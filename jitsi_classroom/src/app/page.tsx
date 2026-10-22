'use client';

import React, { useState } from 'react';
import VirtualClassroom from '../components/VirtualClassroom';
import { ClassroomUser, LiveSessionMetadata, SessionStatus, FallbackProvider } from '../types/classroom';

export default function ClassroomPage() {
  // Current active user toggle (Instructor vs Student)
  const [currentUser, setCurrentUser] = useState<ClassroomUser>({
    id: 'user-instructor-01',
    name: 'Dr. Sarah Connor',
    email: 'sarah.connor@examinantt.edu',
    role: 'instructor',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
  });

  // Current session metadata
  const [session, setSession] = useState<LiveSessionMetadata>({
    id: 'session-101',
    courseId: 'course-cs101',
    courseTitle: 'Advanced Data Structures & Algorithms',
    title: 'Lecture 12: Graph Traversal & Dijkstra Algorithm',
    description: 'Deep dive into shortest paths, priority queues, and real-world network routing protocols.',
    instructorId: 'user-instructor-01',
    instructorName: 'Dr. Sarah Connor',
    status: 'scheduled',
    scheduledStartTime: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
    roomName: 'cs101-graph-traversal',
    fallbackProvider: 'jitsi',
  });

  const toggleRole = (role: 'instructor' | 'student') => {
    if (role === 'instructor') {
      setCurrentUser({
        id: 'user-instructor-01',
        name: 'Dr. Sarah Connor',
        email: 'sarah.connor@examinantt.edu',
        role: 'instructor',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      });
    } else {
      setCurrentUser({
        id: 'user-student-42',
        name: 'Alex Johnson',
        email: 'alex.j@student.examinantt.edu',
        role: 'student',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      });
    }
  };

  const handleStateChange = (newStatus: SessionStatus) => {
    const updates: Partial<LiveSessionMetadata> = { status: newStatus };
    if (newStatus === 'live' && !session.startedAt) {
      updates.startedAt = new Date().toISOString();
    }
    if (newStatus === 'completed' && !session.endedAt) {
      updates.endedAt = new Date().toISOString();
    }
    setSession((prev) => ({ ...prev, ...updates }));
  };

  const handleProviderChange = (provider: FallbackProvider) => {
    let fallbackUrl: string | undefined = undefined;
    if (provider === 'zoom') fallbackUrl = 'https://zoom.us/j/1234567890';
    if (provider === 'google_meet') fallbackUrl = 'https://meet.google.com/abc-defg-hij';
    if (provider === 'youtube') fallbackUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

    setSession((prev) => ({
      ...prev,
      fallbackProvider: provider,
      fallbackUrl,
    }));
  };

  return (
    <main className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      {/* Top Navigation & Test Harness Controls */}
      <header className="border-b border-slate-800 bg-slate-900/90 backdrop-blur-md sticky top-0 z-50 px-6 py-3.5">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
          {/* Logo & Brand */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-cyan-400 flex items-center justify-center text-white font-bold text-lg shadow-lg shadow-indigo-600/30">
              E
            </div>
            <div>
              <h1 className="text-base font-bold text-white tracking-tight">Examinantt Live Classroom</h1>
              <p className="text-[11px] text-slate-400">Enterprise Jitsi / 8x8 JaaS Virtual Engine</p>
            </div>
          </div>

          {/* Interactive Test Bar */}
          <div className="flex flex-wrap items-center gap-3 text-xs">
            {/* Role Switcher */}
            <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800">
              <button
                onClick={() => toggleRole('instructor')}
                className={`px-3 py-1.5 rounded-lg font-medium transition-all ${
                  currentUser.role === 'instructor'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                👨‍🏫 Instructor
              </button>
              <button
                onClick={() => toggleRole('student')}
                className={`px-3 py-1.5 rounded-lg font-medium transition-all ${
                  currentUser.role === 'student'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                🎓 Student
              </button>
            </div>

            {/* State Switcher */}
            <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800">
              {(['not_scheduled', 'scheduled', 'live', 'completed'] as SessionStatus[]).map((st) => (
                <button
                  key={st}
                  onClick={() => handleStateChange(st)}
                  className={`px-2.5 py-1.5 rounded-lg capitalize font-medium transition-all ${
                    session.status === st
                      ? 'bg-slate-800 text-cyan-400 border border-slate-700'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {st.replace('_', ' ')}
                </button>
              ))}
            </div>

            {/* Engine / Fallback Switcher */}
            <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800">
              {(['jitsi', 'zoom', 'google_meet', 'youtube'] as FallbackProvider[]).map((prov) => (
                <button
                  key={prov}
                  onClick={() => handleProviderChange(prov)}
                  className={`px-2.5 py-1.5 rounded-lg capitalize font-medium transition-all ${
                    session.fallbackProvider === prov
                      ? 'bg-slate-800 text-indigo-400 border border-slate-700'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {prov.replace('_', ' ')}
                </button>
              ))}
            </div>
          </div>

          {/* User Profile Pill */}
          <div className="flex items-center gap-2.5 pl-3 border-l border-slate-800">
            <div className="w-8 h-8 rounded-full bg-slate-800 border border-slate-700 overflow-hidden flex items-center justify-center text-xs font-bold text-slate-300">
              {currentUser.name.charAt(0)}
            </div>
            <div className="hidden sm:block text-left">
              <p className="text-xs font-semibold text-white leading-none">{currentUser.name}</p>
              <p className="text-[10px] text-slate-400 capitalize mt-0.5">{currentUser.role}</p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <div className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col">
        <VirtualClassroom
          initialSession={session}
          currentUser={currentUser}
          onSessionStatusChange={(sessionId, newStatus, extra) => {
            setSession((prev) => ({
              ...prev,
              status: newStatus,
              ...extra,
            }));
          }}
          className="flex-1"
        />
      </div>
    </main>
  );
}
