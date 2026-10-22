'use client';

import React, { useState, useEffect, useRef } from 'react';
import { LiveSessionMetadata, ClassroomUser, SessionStatus } from '../types/classroom';
import JitsiPlayer, { JitsiPlayerHandle } from './JitsiPlayer';
import SessionTimer from './SessionTimer';
import RecordingUploader from './RecordingUploader';
import ReplayPlayer from './ReplayPlayer';
import FallbackMeetingView from './FallbackMeetingView';

interface VirtualClassroomProps {
  initialSession: LiveSessionMetadata;
  currentUser: ClassroomUser;
  onSessionStatusChange?: (sessionId: string, newStatus: SessionStatus, extra?: Partial<LiveSessionMetadata>) => void;
  className?: string;
}

/**
 * Enterprise Live Virtual Classroom Container
 * Manages the complete 4-state lifecycle:
 * 1. Not Scheduled
 * 2. Scheduled (Instructor: Start Class Now; Student: Waiting with 20-30s polling)
 * 3. Live (Synchronized timer, Instructor 'End For All' & 'Leave', Student 'Leave')
 * 4. Completed (Instructor S3 Resumable Uploader / Replay link; Student 90% progress tracker)
 */
export const VirtualClassroom: React.FC<VirtualClassroomProps> = ({
  initialSession,
  currentUser,
  onSessionStatusChange,
  className = '',
}) => {
  const [session, setSession] = useState<LiveSessionMetadata>(initialSession);
  const [jwtToken, setJwtToken] = useState<string | null>(null);
  const [tokenLoading, setTokenLoading] = useState<boolean>(false);
  const [tokenError, setTokenError] = useState<string | null>(null);
  const [participantCount, setParticipantCount] = useState<number>(1);
  const [hasLeftLocally, setHasLeftLocally] = useState<boolean>(false);

  const jitsiPlayerRef = useRef<JitsiPlayerHandle>(null);
  const isInstructor = currentUser.role === 'instructor';

  // Keep internal session synced if prop changes
  useEffect(() => {
    setSession(initialSession);
  }, [initialSession]);

  // Request secure RS256 JWT when entering live state
  useEffect(() => {
    if (session.status === 'live' && !hasLeftLocally && !session.fallbackProvider?.startsWith('zoom')) {
      fetchLiveToken();
    }
  }, [session.status, hasLeftLocally, session.roomName]);

  const fetchLiveToken = async () => {
    setTokenLoading(true);
    setTokenError(null);
    try {
      const res = await fetch('/api/live-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sessionId: session.id,
          roomName: session.roomName,
          user: currentUser,
        }),
      });

      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.error || 'Failed to authenticate and retrieve live room token.');
      }

      const data = await res.json();
      setJwtToken(data.token);
    } catch (err: any) {
      console.error('[VirtualClassroom] Error fetching live token:', err);
      setTokenError(err?.message || 'Authentication error.');
    } finally {
      setTokenLoading(false);
    }
  };

  /**
   * State 2 Detail: Background Polling Mechanism for Students in Scheduled State
   * Polls every 20-30 seconds so student auto-joins the live room once instructor starts.
   */
  useEffect(() => {
    // Only students in scheduled state need to poll
    if (isInstructor || session.status !== 'scheduled') {
      return;
    }

    console.log('[VirtualClassroom] Initiating student background polling (every 20s)...');
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/sessions/${session.id}`);
        if (res.ok) {
          const updated: LiveSessionMetadata = await res.json();
          if (updated.status === 'live') {
            console.log('[VirtualClassroom] Session is now LIVE! Auto-transitioning student...');
            setSession(updated);
            onSessionStatusChange?.(session.id, 'live', updated);
          } else if (updated.status !== session.status) {
            setSession(updated);
          }
        }
      } catch (e) {
        console.warn('[VirtualClassroom] Background polling tick failed:', e);
      }
    }, 20000); // 20 seconds polling interval

    return () => clearInterval(interval);
  }, [isInstructor, session.status, session.id]);

  // Handler: Instructor clicks "Start Class Now"
  const handleStartClass = async () => {
    const startedAt = new Date().toISOString();
    const updatedSession: LiveSessionMetadata = {
      ...session,
      status: 'live',
      startedAt,
    };

    setSession(updatedSession);
    setHasLeftLocally(false);

    // Update backend database
    try {
      await fetch(`/api/sessions/${session.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'live', startedAt }),
      });
    } catch (e) {
      console.error('Failed to notify backend of live status start:', e);
    }

    onSessionStatusChange?.(session.id, 'live', { startedAt });
  };

  // Handler: Instructor clicks "End for All"
  const handleEndConferenceForAll = async () => {
    const confirmEnd = window.confirm(
      'Are you sure you want to end the lecture for all attendees? This will close the live room.'
    );
    if (!confirmEnd) return;

    if (jitsiPlayerRef.current) {
      jitsiPlayerRef.current.endConferenceForAll();
    }

    const endedAt = new Date().toISOString();
    const updatedSession: LiveSessionMetadata = {
      ...session,
      status: 'completed',
      endedAt,
    };

    setSession(updatedSession);

    // Update backend database
    try {
      await fetch(`/api/sessions/${session.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'completed', endedAt }),
      });
    } catch (e) {
      console.error('Failed to update DB on conference end:', e);
    }

    onSessionStatusChange?.(session.id, 'completed', { endedAt });
  };

  // Handler: Instructor or Student clicks "Leave Room" / "Leave Class" locally
  const handleLeaveLocally = () => {
    if (jitsiPlayerRef.current) {
      jitsiPlayerRef.current.leaveClassLocally();
    }
    setHasLeftLocally(true);
  };

  // Handler: Rejoin live room
  const handleRejoin = () => {
    setHasLeftLocally(false);
  };

  // Handler: Save recording URL (Instructor in Completed state)
  const handleRecordingSaved = async (url: string) => {
    const updated = { ...session, recordingUrl: url };
    setSession(updated);

    try {
      await fetch(`/api/sessions/${session.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recordingUrl: url }),
      });
    } catch (e) {
      console.error('Failed to save recording URL:', e);
    }

    onSessionStatusChange?.(session.id, 'completed', { recordingUrl: url });
  };

  // Handler: Lesson Completed (Student watches 90%+ replay)
  const handleLessonCompleted = async (sId: string, stId?: string) => {
    try {
      await fetch(`/api/sessions/${sId}/complete-lesson`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sessionId: sId,
          studentId: stId || currentUser.id,
          completedAt: new Date().toISOString(),
        }),
      });
    } catch (e) {
      console.error('Failed to record lesson completion:', e);
    }
  };

  // Render Fallback if provider is Zoom / Google Meet / YouTube Live
  if (
    session.fallbackProvider &&
    session.fallbackProvider !== 'jitsi' &&
    session.status !== 'completed'
  ) {
    return <FallbackMeetingView session={session} user={currentUser} className={className} />;
  }

  return (
    <div className={`flex flex-col w-full h-full min-h-[700px] ${className}`}>
      {/* =========================================================================
          STATE 1: NOT SCHEDULED
         ========================================================================= */}
      {session.status === 'not_scheduled' && (
        <div className="flex-1 flex flex-col items-center justify-center p-8 bg-slate-900/60 border border-slate-800 rounded-3xl backdrop-blur-md text-center max-w-2xl mx-auto my-auto shadow-2xl">
          <div className="w-16 h-16 rounded-2xl bg-slate-800 border border-slate-700/80 flex items-center justify-center text-3xl mb-4 text-slate-400 shadow-inner">
            📅
          </div>
          <span className="px-3 py-1 bg-slate-800/80 border border-slate-700 text-slate-400 rounded-full text-xs font-semibold uppercase tracking-wider mb-3">
            Classroom Status
          </span>
          <h2 className="text-2xl font-bold text-white mb-2">{session.title}</h2>
          <p className="text-sm text-slate-400 max-w-md mb-6">
            This live classroom session has not been scheduled yet. The instructor will announce the time once finalized.
          </p>
          <div className="flex items-center gap-4 text-xs text-slate-500 bg-slate-950/60 px-5 py-3 rounded-xl border border-slate-800">
            <span>Course: {session.courseTitle}</span>
            <span>•</span>
            <span>Instructor: {session.instructorName}</span>
          </div>
        </div>
      )}

      {/* =========================================================================
          STATE 2: SCHEDULED
         ========================================================================= */}
      {session.status === 'scheduled' && (
        <div className="flex-1 flex flex-col items-center justify-center p-8 bg-slate-900/60 border border-slate-800 rounded-3xl backdrop-blur-md text-center max-w-2xl mx-auto my-auto shadow-2xl">
          <div className="w-16 h-16 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-3xl mb-4 text-indigo-400 shadow-inner">
            ⏳
          </div>

          <span className="px-3 py-1 bg-indigo-500/10 border border-indigo-500/30 text-indigo-300 rounded-full text-xs font-semibold uppercase tracking-wider mb-3">
            Upcoming Live Lecture
          </span>

          <h2 className="text-2xl font-bold text-white mb-2">{session.title}</h2>
          <p className="text-sm text-slate-400 max-w-md mb-4">
            {session.description || 'Join on time with your audio muted and camera ready.'}
          </p>

          {session.scheduledStartTime && (
            <div className="mb-6 px-4 py-2 bg-slate-950/80 border border-slate-800 rounded-xl text-xs font-mono text-cyan-400">
              Scheduled For: {new Date(session.scheduledStartTime).toLocaleString()}
            </div>
          )}

          {/* Instructor Controls */}
          {isInstructor ? (
            <div className="space-y-3 w-full max-w-xs">
              <button
                onClick={handleStartClass}
                className="w-full py-3 px-6 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-2"
              >
                <span>Start Class Now</span>
                <span>🚀</span>
              </button>
              <p className="text-[11px] text-slate-500">
                You are the instructor. Launching the room will notify connected students.
              </p>
            </div>
          ) : (
            /* Student View: Waiting State with Gentle Polling Active */
            <div className="space-y-4">
              <div className="inline-flex items-center gap-3 px-5 py-3 rounded-2xl bg-slate-950/80 border border-slate-800">
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-amber-500"></span>
                </span>
                <span className="text-sm font-medium text-slate-300">
                  Waiting for instructor to start the class...
                </span>
              </div>
              <p className="text-xs text-slate-500">
                Checking classroom status every 20 seconds. This page will automatically enter the live room when the host begins.
              </p>
            </div>
          )}
        </div>
      )}

      {/* =========================================================================
          STATE 3: LIVE
         ========================================================================= */}
      {session.status === 'live' && (
        <div className="flex-1 flex flex-col w-full h-full space-y-4">
          {/* Live Top Header Control Bar */}
          <div className="flex flex-wrap items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900/90 border border-slate-800 backdrop-blur-md shadow-lg">
            <div className="flex items-center gap-3">
              <SessionTimer startedAt={session.startedAt} isLive={true} />
              <div>
                <h3 className="text-sm font-bold text-white truncate max-w-md">{session.title}</h3>
                <p className="text-xs text-slate-400">
                  Host: <span className="text-slate-200">{session.instructorName}</span>
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              {/* Participant Counter */}
              <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-xs text-slate-300">
                <span>👥</span>
                <span className="font-semibold">{participantCount}</span>
                <span className="text-slate-400">in room</span>
              </div>

              {/* Instructor Actions */}
              {isInstructor ? (
                <>
                  <button
                    onClick={handleLeaveLocally}
                    className="px-3.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold transition-all border border-slate-700"
                    title="Leave conference locally; room stays active for students"
                  >
                    Leave Room
                  </button>
                  <button
                    onClick={handleEndConferenceForAll}
                    className="px-3.5 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-semibold transition-all shadow-md shadow-rose-600/30"
                    title="Forcefully terminate conference for everyone"
                  >
                    End for All 🛑
                  </button>
                </>
              ) : (
                /* Student Actions */
                <button
                  onClick={handleLeaveLocally}
                  className="px-3.5 py-1.5 rounded-xl bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 text-xs font-semibold transition-all border border-rose-500/30"
                >
                  Leave Class
                </button>
              )}
            </div>
          </div>

          {/* Player Mount or Local Leave Screen */}
          <div className="flex-1 w-full min-h-[600px] relative">
            {hasLeftLocally ? (
              <div className="w-full h-full min-h-[600px] rounded-2xl bg-slate-900 border border-slate-800 flex flex-col items-center justify-center p-8 text-center">
                <div className="w-14 h-14 rounded-2xl bg-slate-800 flex items-center justify-center text-2xl text-slate-400 mb-4">
                  👋
                </div>
                <h3 className="text-xl font-bold text-white mb-2">You Left the Live Classroom</h3>
                <p className="text-sm text-slate-400 max-w-sm mb-6">
                  The lecture is still ongoing. You can rejoin the live room at any time.
                </p>
                <button
                  onClick={handleRejoin}
                  className="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg shadow-indigo-600/30"
                >
                  Rejoin Live Class ⚡
                </button>
              </div>
            ) : tokenLoading ? (
              <div className="w-full h-full min-h-[600px] rounded-2xl bg-slate-950 border border-slate-800 flex flex-col items-center justify-center">
                <div className="w-10 h-10 rounded-full border-4 border-indigo-500 border-t-transparent animate-spin mb-4"></div>
                <p className="text-sm font-medium text-slate-300">Generating secure classroom credentials...</p>
              </div>
            ) : tokenError ? (
              <div className="w-full h-full min-h-[600px] rounded-2xl bg-slate-950 border border-slate-800 flex flex-col items-center justify-center p-6 text-center">
                <p className="text-rose-400 font-semibold mb-2">Room Authentication Error</p>
                <p className="text-xs text-slate-400 max-w-md mb-4">{tokenError}</p>
                <button
                  onClick={fetchLiveToken}
                  className="px-4 py-2 bg-indigo-600 text-white text-xs rounded-xl"
                >
                  Retry Authentication
                </button>
              </div>
            ) : (
              <JitsiPlayer
                ref={jitsiPlayerRef}
                roomName={session.roomName}
                jwtToken={jwtToken || undefined}
                user={currentUser}
                instructorId={session.instructorId}
                instructorName={session.instructorName}
                onParticipantCountChange={(count) => setParticipantCount(count)}
                onConferenceLeft={() => setHasLeftLocally(true)}
              />
            )}
          </div>
        </div>
      )}

      {/* =========================================================================
          STATE 4: COMPLETED
         ========================================================================= */}
      {session.status === 'completed' && (
        <div className="flex-1 flex flex-col w-full h-full space-y-6">
          {/* Header Banner */}
          <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between">
            <div>
              <span className="px-2.5 py-0.5 rounded-full bg-slate-800 text-slate-400 text-[10px] font-semibold uppercase tracking-wider">
                Lecture Finished
              </span>
              <h3 className="text-lg font-bold text-white mt-1">{session.title}</h3>
            </div>
            {session.endedAt && (
              <p className="text-xs text-slate-400">
                Ended on: {new Date(session.endedAt).toLocaleDateString()}
              </p>
            )}
          </div>

          {/* Completed State: Replay Player or Recording Upload */}
          {session.recordingUrl ? (
            <div className="space-y-4">
              <ReplayPlayer
                sessionId={session.id}
                recordingUrl={session.recordingUrl}
                studentId={currentUser.id}
                onLessonCompleted={handleLessonCompleted}
              />
              {isInstructor && (
                <div className="flex justify-end">
                  <button
                    onClick={() => setSession({ ...session, recordingUrl: undefined })}
                    className="text-xs text-slate-400 hover:text-slate-200 underline"
                  >
                    Replace Recording Link
                  </button>
                </div>
              )}
            </div>
          ) : isInstructor ? (
            <RecordingUploader
              sessionId={session.id}
              onRecordingSaved={handleRecordingSaved}
            />
          ) : (
            <div className="p-12 text-center rounded-2xl bg-slate-900/60 border border-slate-800">
              <div className="w-14 h-14 mx-auto rounded-2xl bg-slate-800 flex items-center justify-center text-2xl text-slate-400 mb-3">
                ⏳
              </div>
              <h4 className="text-base font-semibold text-white mb-1">Recording Processing</h4>
              <p className="text-xs text-slate-400 max-w-sm mx-auto">
                The live session has completed. The instructor will upload the replay recording shortly. Please check back soon.
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default VirtualClassroom;
