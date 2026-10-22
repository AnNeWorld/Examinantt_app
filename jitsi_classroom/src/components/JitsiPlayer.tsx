'use client';

import React, { useEffect, useRef, useState, useImperativeHandle, forwardRef } from 'react';
import { ClassroomUser } from '../types/classroom';

export interface JitsiPlayerHandle {
  executeCommand: (command: string, ...args: any[]) => void;
  endConferenceForAll: () => void;
  leaveClassLocally: () => void;
  isReady: () => boolean;
}

export interface JitsiPlayerProps {
  roomName: string;
  jwtToken?: string;
  user: ClassroomUser;
  domain?: string;
  appId?: string;
  instructorId?: string;
  instructorName?: string;
  onConferenceJoined?: (event: any) => void;
  onConferenceLeft?: (event: any) => void;
  onParticipantJoined?: (participant: any) => void;
  onParticipantLeft?: (participant: any) => void;
  onParticipantCountChange?: (count: number) => void;
  onError?: (error: Error) => void;
}

declare global {
  interface Window {
    JitsiMeetExternalAPI: any;
  }
}

/**
 * Enterprise-grade Jitsi Meet / 8x8 JaaS Player Component
 * Features:
 * - Dynamic script loader with singleton promise deduplication
 * - Role-based toolbars for Instructor vs. Student
 * - Strict security & moderation overrides (disable kick, remote mute, grant moderator for students)
 * - Self-healing moderator safeguard (reverts accidental moderator promo back to host)
 * - P2P disabled for enterprise SFU multi-party stability
 */
export const JitsiPlayer = forwardRef<JitsiPlayerHandle, JitsiPlayerProps>(function JitsiPlayer(
  {
    roomName,
    jwtToken,
    user,
    domain = process.env.NEXT_PUBLIC_JITSI_DOMAIN || '8x8.vc',
    appId = process.env.NEXT_PUBLIC_JAAS_APP_ID || 'vpaas-magic-cookie-fe717ca9148443d190318fca9291b5ff',
    instructorId,
    instructorName,
    onConferenceJoined,
    onConferenceLeft,
    onParticipantJoined,
    onParticipantLeft,
    onParticipantCountChange,
    onError,
  },
  ref
) {
  const containerRef = useRef<HTMLDivElement>(null);
  const apiRef = useRef<any>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const isInstructor = user.role === 'instructor';
  const participantsMapRef = useRef<Map<string, { id: string; displayName: string; role?: string }>>(new Map());
  const localParticipantIdRef = useRef<string | null>(null);

  // Expose imperative actions to parent (e.g. End For All, Leave Room)
  useImperativeHandle(ref, () => ({
    executeCommand: (command: string, ...args: any[]) => {
      if (apiRef.current) {
        apiRef.current.executeCommand(command, ...args);
      }
    },
    endConferenceForAll: () => {
      if (apiRef.current) {
        console.log('[JitsiPlayer] Instructor ending conference for all participants.');
        apiRef.current.executeCommand('endConference');
      }
    },
    leaveClassLocally: () => {
      if (apiRef.current) {
        console.log('[JitsiPlayer] Leaving conference locally.');
        apiRef.current.executeCommand('hangup');
      }
    },
    isReady: () => !!apiRef.current,
  }));

  // Load Jitsi Meet External API Script
  useEffect(() => {
    let isMounted = true;

    const loadJitsiScript = (): Promise<void> => {
      return new Promise((resolve, reject) => {
        if (typeof window !== 'undefined' && window.JitsiMeetExternalAPI) {
          return resolve();
        }

        const scriptId = 'jitsi-external-api-script';
        const existingScript = document.getElementById(scriptId) as HTMLScriptElement | null;
        if (existingScript) {
          existingScript.addEventListener('load', () => resolve());
          existingScript.addEventListener('error', (e) => reject(e));
          return;
        }

        const script = document.createElement('script');
        script.id = scriptId;
        // 8x8 JaaS external api URL path
        if (domain.includes('8x8.vc')) {
          script.src = appId ? `https://${domain}/${appId}/external_api.js` : `https://${domain}/external_api.js`;
        } else {
          script.src = `https://${domain}/external_api.js`;
        }
        script.async = true;

        script.onload = () => resolve();
        script.onerror = (err) => {
          console.error('[JitsiPlayer] Failed to load Jitsi External API script from', script.src, err);
          reject(new Error(`Failed to load Jitsi API script from ${script.src}`));
        };

        document.head.appendChild(script);
      });
    };

    loadJitsiScript()
      .then(() => {
        if (!isMounted || !containerRef.current) return;
        initializeJitsiInstance();
      })
      .catch((err) => {
        if (!isMounted) return;
        const msg = err?.message || 'Error loading Jitsi external API';
        setLoadError(msg);
        setLoading(false);
        onError?.(err);
      });

    return () => {
      isMounted = false;
      if (apiRef.current) {
        console.log('[JitsiPlayer] Disposing Jitsi API instance...');
        try {
          apiRef.current.dispose();
        } catch (e) {
          console.error('[JitsiPlayer] Error during Jitsi dispose:', e);
        }
        apiRef.current = null;
      }
    };
  }, [roomName, jwtToken, domain, appId]);

  const initializeJitsiInstance = () => {
    if (!containerRef.current || !window.JitsiMeetExternalAPI) return;

    // Dispose existing instance if any
    if (apiRef.current) {
      try {
        apiRef.current.dispose();
      } catch (e) {}
      apiRef.current = null;
    }

    // A. Role-Based Toolbars
    const instructorToolbar = [
      'microphone',
      'camera',
      'desktop',
      'chat',
      'raisehand',
      'participants-pane',
      'tileview',
      'fullscreen',
      'security',
      'mute-everyone',
      'hangup',
    ];

    const studentToolbar = [
      'microphone',
      'camera',
      'chat',
      'raisehand',
      'tileview',
      'fullscreen',
      'hangup',
    ];

    const activeToolbar = isInstructor ? instructorToolbar : studentToolbar;

    // B. Strict Security Configurations (configOverwrite)
    const configOverwrite = {
      // Audio/Video muting on join
      startWithAudioMuted: !isInstructor, // Students enter muted
      startWithVideoMuted: !isInstructor, // Students enter without video
      prejoinPageEnabled: false,          // Bypass prejoin screen for seamless embedding
      disableDeepLinking: true,           // Keep users inside web app, prevent external app prompts

      // LOBBY COMPLETELY DISABLED: Students join instantly, no waiting room
      'lobby.enabled': false,
      enableLobbyChat: false,

      // Critical Moderation Overrides to prevent unauthorized actions
      remoteVideoMenu: {
        disableKick: !isInstructor,           // Students CANNOT kick users
        disableGrantModerator: !isInstructor, // Students CANNOT grant/revoke moderator status
      },
      disableRemoteMute: !isInstructor,       // Students CANNOT mute others
      disableInviteFunctions: true,           // Prevent unauthorized user invitation links

      // Enterprise SFU Multi-party stability
      p2p: {
        enabled: false,                       // Force Jitsi Videobridge routing
      },

      // Toolbar restrictions
      toolbarButtons: activeToolbar,
      enableWelcomePage: false,
      enableClosePage: false,
      defaultRemoteDisplayName: 'Student',
      hideConferenceSubject: false,
      hideConferenceTimer: false,
    };

    const interfaceConfigOverwrite = {
      TOOLBAR_BUTTONS: activeToolbar,
      SHOW_JITSI_WATERMARK: false,
      SHOW_WATERMARK_FOR_GUESTS: false,
      SHOW_BRAND_WATERMARK: false,
      DEFAULT_REMOTE_DISPLAY_NAME: 'Student',
      HIDE_INVITE_MORE_HEADER: true,
      MOBILE_APP_PROMO: false,
    };

    try {
      const options = {
        roomName,
        parentNode: containerRef.current,
        width: '100%',
        height: '100%',
        configOverwrite,
        interfaceConfigOverwrite,
        jwt: jwtToken,
        userInfo: {
          displayName: isInstructor ? `${user.name} (Host)` : user.name,
          email: user.email,
        },
      };

      console.log('[JitsiPlayer] Initializing JitsiMeetExternalAPI for room:', roomName, {
        isInstructor,
        role: user.role,
        domain,
      });

      const api = new window.JitsiMeetExternalAPI(domain, options);
      apiRef.current = api;

      // Event Listeners
      api.addEventListener('videoConferenceJoined', (event: any) => {
        console.log('[JitsiPlayer] Local participant joined conference:', event);
        localParticipantIdRef.current = event.id;
        setLoading(false);
        onConferenceJoined?.(event);
        updateParticipantCount();
      });

      api.addEventListener('videoConferenceLeft', (event: any) => {
        console.log('[JitsiPlayer] Local participant left conference:', event);
        onConferenceLeft?.(event);
      });

      api.addEventListener('participantJoined', (participant: any) => {
        console.log('[JitsiPlayer] Remote participant joined:', participant);
        participantsMapRef.current.set(participant.id, {
          id: participant.id,
          displayName: participant.displayName || 'Participant',
          role: participant.role,
        });
        updateParticipantCount();
        onParticipantJoined?.(participant);
      });

      api.addEventListener('participantLeft', (participant: any) => {
        console.log('[JitsiPlayer] Remote participant left:', participant);
        participantsMapRef.current.delete(participant.id);
        updateParticipantCount();
        onParticipantLeft?.(participant);
      });

      // C. Moderator Self-Healing Mechanism (Edge Case Protection)
      api.addEventListener('participantRoleChanged', (event: any) => {
        console.log('[JitsiPlayer] Role changed event:', event);

        // Update participant role cache
        const cached = participantsMapRef.current.get(event.id);
        if (cached) {
          cached.role = event.role;
        }

        // If this client is a STUDENT, but was granted the 'moderator' role by Jitsi
        // (which can occur if the host briefly disconnected or dropped):
        if (!isInstructor && event.id === localParticipantIdRef.current && event.role === 'moderator') {
          console.warn(
            '[JitsiPlayer] Self-Healing Safeguard triggered: Student was mistakenly assigned moderator role. Searching for instructor...'
          );

          let hostParticipantId: string | null = null;

          participantsMapRef.current.forEach((p, pId) => {
            const name = (p.displayName || '').toLowerCase();
            const hostIndicator = name.includes('(host)') || 
              (instructorName && name.includes(instructorName.toLowerCase())) ||
              (instructorId && p.id === instructorId);

            if (hostIndicator) {
              hostParticipantId = pId;
            }
          });

          if (hostParticipantId) {
            console.log(
              `[JitsiPlayer] Self-Healing: Immediately returning moderator role to Host (participant ${hostParticipantId})`
            );
            api.executeCommand('grantModerator', hostParticipantId);
          } else {
            console.warn('[JitsiPlayer] Self-Healing: Host participant not currently found in participant list.');
          }
        }
      });

      api.addEventListener('readyToClose', () => {
        console.log('[JitsiPlayer] Jitsi ready to close event.');
        onConferenceLeft?.({ reason: 'readyToClose' });
      });
    } catch (err: any) {
      console.error('[JitsiPlayer] Failed to instantiate JitsiMeetExternalAPI:', err);
      setLoadError(err?.message || 'Failed to initialize Jitsi room.');
      setLoading(false);
      onError?.(err);
    }
  };

  const updateParticipantCount = () => {
    // Local participant (+1) + remote participants
    const count = 1 + participantsMapRef.current.size;
    onParticipantCountChange?.(count);
  };

  return (
    <div className="relative w-full h-full min-h-[600px] bg-slate-950 rounded-2xl overflow-hidden shadow-2xl border border-slate-800">
      {/* Loading Overlay */}
      {loading && !loadError && (
        <div className="absolute inset-0 z-20 flex flex-col items-center justify-center bg-slate-950/90 backdrop-blur-md">
          <div className="relative w-16 h-16 mb-4">
            <div className="absolute inset-0 rounded-full border-4 border-indigo-500/20 animate-ping"></div>
            <div className="w-16 h-16 rounded-full border-4 border-indigo-500 border-t-transparent animate-spin"></div>
          </div>
          <h3 className="text-lg font-semibold text-white tracking-wide">Connecting to Secure Live Classroom...</h3>
          <p className="text-sm text-slate-400 mt-1">Configuring role-based permissions & media stream...</p>
        </div>
      )}

      {/* Error Overlay */}
      {loadError && (
        <div className="absolute inset-0 z-20 flex flex-col items-center justify-center bg-slate-950 p-6 text-center">
          <div className="w-14 h-14 rounded-2xl bg-rose-500/10 border border-rose-500/30 flex items-center justify-center text-rose-400 mb-4 text-2xl">
            ⚠️
          </div>
          <h3 className="text-xl font-bold text-white mb-2">Classroom Connection Error</h3>
          <p className="text-sm text-rose-300/80 max-w-md mb-6">{loadError}</p>
          <button
            onClick={() => {
              setLoadError(null);
              setLoading(true);
              initializeJitsiInstance();
            }}
            className="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-medium transition-all shadow-lg shadow-indigo-600/30"
          >
            Retry Connection
          </button>
        </div>
      )}

      {/* Jitsi Iframe Mount Target */}
      <div ref={containerRef} className="w-full h-full" id="jitsi-meet-player-container" />
    </div>
  );
});

export default JitsiPlayer;
