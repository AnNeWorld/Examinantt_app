'use client';

import React, { useState } from 'react';
import { LiveSessionMetadata, ClassroomUser } from '../types/classroom';

interface FallbackMeetingViewProps {
  session: LiveSessionMetadata;
  user: ClassroomUser;
  className?: string;
}

/**
 * Fallback Meeting Viewer for external video engines:
 * - Zoom
 * - Google Meet
 * - YouTube Live Broadcasts
 */
export const FallbackMeetingView: React.FC<FallbackMeetingViewProps> = ({
  session,
  user,
  className = '',
}) => {
  const [copied, setCopied] = useState(false);
  const provider = session.fallbackProvider || 'zoom';
  const meetingUrl = session.fallbackUrl || '';

  const getProviderMeta = () => {
    switch (provider) {
      case 'zoom':
        return {
          name: 'Zoom Meeting',
          icon: '📹',
          brandColor: 'bg-blue-600 hover:bg-blue-500',
          accentBorder: 'border-blue-500/30',
          gradient: 'from-blue-600/20 to-indigo-600/10',
          instructions: 'This lecture is hosted on Zoom. Click below to launch the Zoom Client or Web App.',
        };
      case 'google_meet':
        return {
          name: 'Google Meet',
          icon: '🟢',
          brandColor: 'bg-emerald-600 hover:bg-emerald-500',
          accentBorder: 'border-emerald-500/30',
          gradient: 'from-emerald-600/20 to-teal-600/10',
          instructions: 'This lecture is hosted on Google Meet. Click below to join with your browser.',
        };
      case 'youtube':
        return {
          name: 'YouTube Live',
          icon: '🔴',
          brandColor: 'bg-red-600 hover:bg-red-500',
          accentBorder: 'border-red-500/30',
          gradient: 'from-red-600/20 to-rose-600/10',
          instructions: 'This lecture is being broadcast live via YouTube Stream.',
        };
      default:
        return {
          name: 'External Conference',
          icon: '🔗',
          brandColor: 'bg-indigo-600 hover:bg-indigo-500',
          accentBorder: 'border-indigo-500/30',
          gradient: 'from-indigo-600/20 to-violet-600/10',
          instructions: 'Join the external meeting using the provided link.',
        };
    }
  };

  const meta = getProviderMeta();

  const handleCopyLink = () => {
    if (!meetingUrl) return;
    navigator.clipboard.writeText(meetingUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 3000);
  };

  const getYouTubeEmbedUrl = (url: string): string => {
    try {
      if (url.includes('youtu.be/')) {
        const id = url.split('youtu.be/')[1]?.split('?')[0];
        return `https://www.youtube.com/embed/${id}?autoplay=1`;
      }
      const u = new URL(url);
      const v = u.searchParams.get('v');
      return `https://www.youtube.com/embed/${v}?autoplay=1`;
    } catch {
      return url;
    }
  };

  // If YouTube Live broadcast, embed player directly
  if (provider === 'youtube' && meetingUrl) {
    return (
      <div className={`w-full rounded-2xl overflow-hidden bg-slate-950 border border-slate-800 shadow-2xl ${className}`}>
        <div className="p-4 bg-slate-900 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse"></span>
            <span className="text-xs font-bold text-white uppercase tracking-wider">YouTube Live Stream</span>
          </div>
          <span className="text-xs text-slate-400">Instructor: {session.instructorName}</span>
        </div>
        <div className="aspect-video w-full bg-black">
          <iframe
            src={getYouTubeEmbedUrl(meetingUrl)}
            title="YouTube Live Broadcast"
            className="w-full h-full border-0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
      </div>
    );
  }

  return (
    <div
      className={`p-8 rounded-2xl bg-gradient-to-br ${meta.gradient} bg-slate-900 border ${meta.accentBorder} shadow-2xl text-center max-w-xl mx-auto my-8 ${className}`}
    >
      <div className="w-16 h-16 mx-auto rounded-2xl bg-slate-800/80 border border-slate-700 flex items-center justify-center text-3xl mb-5 shadow-lg">
        {meta.icon}
      </div>

      <span className="px-3 py-1 rounded-full text-xs font-semibold bg-slate-800/80 text-slate-300 border border-slate-700/60 uppercase tracking-widest inline-block mb-3">
        External Classroom Fallback
      </span>

      <h3 className="text-2xl font-bold text-white mb-2">{session.title}</h3>
      <p className="text-sm text-slate-300 mb-6 max-w-md mx-auto">{meta.instructions}</p>

      <div className="space-y-3">
        {meetingUrl ? (
          <>
            <a
              href={meetingUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={`inline-flex items-center justify-center gap-2 w-full py-3 px-6 ${meta.brandColor} text-white font-semibold rounded-xl transition-all shadow-lg text-sm`}
            >
              <span>Launch {meta.name}</span>
              <span>↗</span>
            </a>

            <button
              onClick={handleCopyLink}
              className="w-full py-2.5 px-4 bg-slate-800/80 hover:bg-slate-700/80 text-slate-300 text-xs rounded-xl font-medium transition-all border border-slate-700"
            >
              {copied ? '✓ Meeting Link Copied' : '📋 Copy Meeting Link'}
            </button>
          </>
        ) : (
          <div className="p-4 bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs rounded-xl">
            Meeting link has not been published yet. Please check back shortly.
          </div>
        )}
      </div>

      <div className="mt-6 pt-5 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
        <span>Instructor: {session.instructorName}</span>
        <span>Role: {user.role === 'instructor' ? 'Host' : 'Attendee'}</span>
      </div>
    </div>
  );
};

export default FallbackMeetingView;
