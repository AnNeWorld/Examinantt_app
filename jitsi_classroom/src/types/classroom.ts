export type UserRole = 'instructor' | 'student';

export type SessionStatus = 'not_scheduled' | 'scheduled' | 'live' | 'completed';

export type FallbackProvider = 'jitsi' | 'zoom' | 'google_meet' | 'youtube';

export interface ClassroomUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl?: string;
}

export interface LiveSessionMetadata {
  id: string;
  courseId: string;
  courseTitle: string;
  title: string;
  description?: string;
  instructorId: string;
  instructorName: string;
  status: SessionStatus;
  scheduledStartTime?: string;
  startedAt?: string;
  endedAt?: string;
  durationMinutes?: number;
  roomName: string;
  recordingUrl?: string;
  fallbackProvider?: FallbackProvider;
  fallbackUrl?: string;
}

export interface JitsiParticipant {
  id: string;
  displayName: string;
  role?: string;
  isHost?: boolean;
}

export interface LiveTokenRequest {
  sessionId: string;
  roomName: string;
  user: ClassroomUser;
}

export interface LiveTokenResponse {
  token: string;
  roomName: string;
  domain: string;
  appId: string;
}
