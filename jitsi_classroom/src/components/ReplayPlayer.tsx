'use client';

import React, { useState, useRef, useEffect } from 'react';

interface ReplayPlayerProps {
  sessionId: string;
  recordingUrl: string;
  studentId?: string;
  isCompleted?: boolean;
  onLessonCompleted?: (sessionId: string, studentId?: string) => void;
  className?: string;
}

/**
 * Replay Video Player with Automated 90% Completion Tracking
 * Detects playback progress and automatically triggers course completion once student watches > 90%.
 */
export const ReplayPlayer: React.FC<ReplayPlayerProps> = ({
  sessionId,
  recordingUrl,
  studentId,
  isCompleted = false,
  onLessonCompleted,
  className = '',
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [completed, setCompleted] = useState<boolean>(isCompleted);
  const [progressPercent, setProgressPercent] = useState<number>(0);
  const [showToast, setShowToast] = useState<boolean>(false);
  const completionReportedRef = useRef<boolean>(isCompleted);

  const isYouTube = recordingUrl.includes('youtube.com') || recordingUrl.includes('youtu.be');
  const isVimeo = recordingUrl.includes('vimeo.com');

  const getYouTubeEmbedUrl = (url: string): string => {
    try {
      if (url.includes('youtu.be/')) {
        const id = url.split('youtu.be/')[1]?.split('?')[0];
        return `https://www.youtube.com/embed/${id}?enablejsapi=1&autoplay=0`;
      }
      const u = new URL(url);
      const v = u.searchParams.get('v');
      return `https://www.youtube.com/embed/${v}?enablejsapi=1&autoplay=0`;
    } catch {
      return url;
    }
  };

  const handleTimeUpdate = () => {
    if (!videoRef.current) return;
    const { currentTime, duration } = videoRef.current;
    if (!duration || isNaN(duration)) return;

    const percent = Math.floor((currentTime / duration) * 100);
    setProgressPercent(percent);

    // Automated 90% Completion Threshold Check
    if (percent >= 90 && !completionReportedRef.current) {
      completionReportedRef.current = true;
      setCompleted(true);
      setShowToast(true);

      console.log(`[ReplayPlayer] Video progress reached ${percent}%. Marking session ${sessionId} as completed for student.`);
      
      // Notify parent & API
      onLessonCompleted?.(sessionId, studentId);

      // Hide toast after 5s
      setTimeout(() => setShowToast(false), 5000);
    }
  };

  return (
    <div className={`relative w-full rounded-2xl overflow-hidden bg-slate-950 border border-slate-800 shadow-2xl ${className}`}>
      {/* Video Container */}
      <div className="relative aspect-video w-full bg-black">
        {isYouTube ? (
          <iframe
            src={getYouTubeEmbedUrl(recordingUrl)}
            title="Class Recording Replay"
            className="w-full h-full border-0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        ) : (
          <video
            ref={videoRef}
            src={recordingUrl}
            onTimeUpdate={handleTimeUpdate}
            controls
            className="w-full h-full object-contain"
            playsInline
          />
        )}

        {/* Completion Toast Notification */}
        {showToast && (
          <div className="absolute top-4 right-4 z-30 animate-bounce bg-emerald-500/90 text-white px-4 py-2.5 rounded-xl text-xs font-semibold shadow-xl backdrop-blur-md flex items-center gap-2 border border-emerald-400">
            <span>🎉</span>
            <span>Lesson Marked Completed (90%+ Watched)!</span>
          </div>
        )}
      </div>

      {/* Progress & Completion Status Bar */}
      <div className="p-4 bg-slate-900 border-t border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div
            className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${
              completed
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                : 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30'
            }`}
          >
            {completed ? '✓' : `${progressPercent}%`}
          </div>

          <div>
            <p className="text-xs font-semibold text-white">
              {completed ? 'Class Attendance & Lesson Completed' : 'Watching Class Replay'}
            </p>
            <p className="text-[11px] text-slate-400">
              {completed
                ? 'Great job! Your progress has been automatically synced with your course.'
                : 'Watch at least 90% of the replay to automatically record attendance.'}
            </p>
          </div>
        </div>

        {completed ? (
          <span className="px-3 py-1 bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 rounded-full text-xs font-medium">
            Completed
          </span>
        ) : (
          <span className="px-3 py-1 bg-slate-800 border border-slate-700 text-slate-300 rounded-full text-xs font-medium">
            {progressPercent}% watched
          </span>
        )}
      </div>
    </div>
  );
};

export default ReplayPlayer;
