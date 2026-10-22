'use client';

import React, { useEffect, useState } from 'react';

interface SessionTimerProps {
  startedAt?: string;
  isLive?: boolean;
  className?: string;
}

/**
 * Synchronized Live Classroom Session Timer
 * Computes elapsed time directly from server-side `startedAt` timestamp to prevent client-side desync.
 */
export const SessionTimer: React.FC<SessionTimerProps> = ({
  startedAt,
  isLive = true,
  className = '',
}) => {
  const [elapsedSeconds, setElapsedSeconds] = useState<number>(0);

  useEffect(() => {
    if (!startedAt) {
      setElapsedSeconds(0);
      return;
    }

    const calculateElapsed = () => {
      const startMs = new Date(startedAt).getTime();
      if (isNaN(startMs)) return 0;
      const nowMs = Date.now();
      const diffSec = Math.max(0, Math.floor((nowMs - startMs) / 1000));
      return diffSec;
    };

    // Initial calculation
    setElapsedSeconds(calculateElapsed());

    if (!isLive) return;

    // Refresh every second
    const interval = setInterval(() => {
      setElapsedSeconds(calculateElapsed());
    }, 1000);

    return () => clearInterval(interval);
  }, [startedAt, isLive]);

  const formatTime = (totalSeconds: number): string => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    const pad = (n: number) => n.toString().padStart(2, '0');

    if (hours > 0) {
      return `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
    }
    return `${pad(minutes)}:${pad(seconds)}`;
  };

  return (
    <div
      className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-900/90 border border-slate-700/80 backdrop-blur-md shadow-inner text-xs font-mono font-medium ${className}`}
    >
      {isLive && (
        <span className="relative flex h-2.5 w-2.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
        </span>
      )}
      <span className="text-slate-400 uppercase tracking-wider text-[10px] font-sans font-semibold">
        {isLive ? 'LIVE' : 'ELAPSED'}
      </span>
      <span className="text-white font-bold">{formatTime(elapsedSeconds)}</span>
    </div>
  );
};

export default SessionTimer;
