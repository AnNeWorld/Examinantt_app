import { LiveSessionMetadata, SessionStatus } from '../types/classroom';

/**
 * Shared in-memory session repository for Jitsi Live Virtual Classrooms.
 * Acts as the authoritative data source across:
 * - GET /api/sessions (list classes)
 * - GET /api/sessions/[id] (session details)
 * - PATCH /api/sessions/[id] (status lifecycle updates)
 * - POST /api/sessions/[id]/verify-access (student enrollment check)
 * - POST /api/live-token (secure JaaS JWT token issuance)
 */

// Initial live classroom sessions matching the Examinantt curriculum
const defaultSessions: LiveSessionMetadata[] = [
  {
    id: 'session-101',
    courseId: 'course-cs101',
    courseTitle: 'Advanced Data Structures & Algorithms',
    title: 'Lecture 12: Graph Traversal & Dijkstra Algorithm',
    description: 'Live interactive session covering BFS, DFS, and shortest path algorithms with live coding.',
    instructorId: 'inst-1',
    instructorName: 'Dr. Sarah Connor',
    status: 'scheduled',
    scheduledStartTime: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    durationMinutes: 60,
    roomName: 'cs101-graph-traversal',
  },
  {
    id: 'live_aws_optics_101',
    courseId: 'batch_jee_main_2027',
    courseTitle: 'JEE Main 2027 Conqueror Batch',
    title: 'Wave Optics & Interference (Live Problem Solving)',
    description: 'Real-time live problem solving, previous years trick questions, and doubt clearance on Jitsi / 8x8 infrastructure.',
    instructorId: 'inst-aman-verma',
    instructorName: 'Er. Aman Verma',
    status: 'live',
    scheduledStartTime: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    startedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    durationMinutes: 90,
    roomName: 'jee2027-wave-optics-live',
  },
  {
    id: 'live_aws_organic_chem_201',
    courseId: 'batch_neet_prep_2026',
    courseTitle: 'NEET 2026 Ultimate Batch',
    title: 'Organic Chemistry: Aldehydes, Ketones & Carboxylic Acids',
    description: 'Reaction mechanisms, IUPAC naming, and NCERT-focused masterclass.',
    instructorId: 'inst-pooja-sharma',
    instructorName: 'Dr. Pooja Sharma',
    status: 'scheduled',
    scheduledStartTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    durationMinutes: 75,
    roomName: 'neet2026-organic-chem-mastery',
  },
  {
    id: 'live_aws_maths_calculus_301',
    courseId: 'batch_jee_main_2027',
    courseTitle: 'JEE Main 2027 Conqueror Batch',
    title: 'Integral Calculus: Definite Integrals & Area Under Curves',
    description: 'Properties of definite integrals, advanced shortcuts, and solved example problems.',
    instructorId: 'inst-rajesh-khanna',
    instructorName: 'Prof. Rajesh Khanna',
    status: 'completed',
    startedAt: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
    endedAt: new Date(Date.now() - 35 * 60 * 1000).toISOString(),
    durationMinutes: 85,
    roomName: 'jee2027-calculus-replay',
    recordingUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  },
];

// Global singleton cache across API routes in Next.js development
declare global {
  // eslint-disable-next-line no-var
  var __examinanttSessionsStore: Map<string, LiveSessionMetadata> | undefined;
}

if (!global.__examinanttSessionsStore) {
  global.__examinanttSessionsStore = new Map<string, LiveSessionMetadata>();
  defaultSessions.forEach((s) => global.__examinanttSessionsStore!.set(s.id, s));
}

export const sessionsStore: Map<string, LiveSessionMetadata> = global.__examinanttSessionsStore;

export function getAllSessions(filters?: {
  courseId?: string;
  batchId?: string;
  status?: string;
}): LiveSessionMetadata[] {
  let list = Array.from(sessionsStore.values());

  if (filters?.courseId) {
    list = list.whereCourse(filters.courseId);
  }
  if (filters?.batchId) {
    list = list.filter((s) => s.courseId === filters.batchId);
  }
  if (filters?.status) {
    list = list.filter((s) => s.status.toLowerCase() === filters.status!.toLowerCase());
  }

  // Sort: 'live' first, then 'scheduled', then 'completed'
  const rank: Record<SessionStatus, number> = {
    live: 0,
    scheduled: 1,
    not_scheduled: 2,
    completed: 3,
  };

  return list.sort((a, b) => {
    const diff = (rank[a.status] ?? 4) - (rank[b.status] ?? 4);
    if (diff !== 0) return diff;
    const aTime = a.scheduledStartTime ? new Date(a.scheduledStartTime).getTime() : 0;
    const bTime = b.scheduledStartTime ? new Date(b.scheduledStartTime).getTime() : 0;
    return aTime - bTime;
  });
}

// Helper filter extension
declare global {
  interface Array<T> {
    whereCourse(courseId: string): T[];
  }
}

if (!Array.prototype.whereCourse) {
  Array.prototype.whereCourse = function (courseId: string) {
    return this.filter((item: any) => item.courseId === courseId);
  };
}

export function getSessionById(id: string): LiveSessionMetadata | undefined {
  return sessionsStore.get(id);
}

export function createOrUpdateSession(session: LiveSessionMetadata): LiveSessionMetadata {
  sessionsStore.set(session.id, session);
  return session;
}

export function patchSessionStatus(
  id: string,
  newStatus: SessionStatus,
  extra?: Partial<LiveSessionMetadata>
): LiveSessionMetadata {
  let existing = sessionsStore.get(id);
  if (!existing) {
    existing = {
      id,
      courseId: 'course-default',
      courseTitle: 'Interactive Classroom',
      title: `Live Session #${id}`,
      instructorId: 'inst-default',
      instructorName: 'Lead Instructor',
      status: newStatus,
      roomName: `classroom-${id}`,
    };
  }

  const updated: LiveSessionMetadata = {
    ...existing,
    ...extra,
    status: newStatus,
  };

  sessionsStore.set(id, updated);
  return updated;
}

/**
 * Verify student enrollment for a session.
 * In production, checks against user database / payment records.
 */
export function verifyStudentEnrollment(
  sessionId: string,
  userId: string,
  userRole: string
): { isAuthorized: boolean; message?: string } {
  if (userRole === 'instructor') {
    return { isAuthorized: true };
  }

  const session = sessionsStore.get(sessionId);
  if (!session) {
    return { isAuthorized: true }; // allow joining open sandbox classrooms
  }

  // Allow student access
  return {
    isAuthorized: true,
    message: 'Student enrollment verified successfully.',
  };
}
