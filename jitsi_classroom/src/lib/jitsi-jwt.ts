import jwt from 'jsonwebtoken';
import { ClassroomUser } from '../types/classroom';

/**
 * Sanitizes room name to prevent invalid characters and collisions.
 * 8x8 JaaS requires format: <jaas_app_id>/<sanitized_room_name>
 */
export function sanitizeRoomName(rawName: string, appId?: string): string {
  const clean = rawName
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9_-]/g, '-')
    .replace(/-+/g, '-');

  const base = clean.length > 0 ? clean : 'virtual-classroom';
  
  if (appId && !base.startsWith(`${appId}/`)) {
    return `${appId}/${base}`;
  }
  return base;
}

/**
 * Generates an RSA-256 signed JWT for 8x8 JaaS / Jitsi Meet External API.
 */
export function generateJitsiToken(params: {
  user: ClassroomUser;
  roomName: string;
  appId?: string;
  apiKeyId?: string;
  privateKey?: string;
}): string {
  const { user, roomName } = params;

  const appId = params.appId || process.env.JAAS_APP_ID || 'vpaas-magic-cookie-app';
  const apiKeyId = params.apiKeyId || process.env.JAAS_API_KEY_ID || `${appId}/sample-key-id`;
  let privateKey = params.privateKey || process.env.JAAS_PRIVATE_KEY || '';

  if (!privateKey) {
    throw new Error(
      'Missing JAAS_PRIVATE_KEY environment variable. An RSA-256 private key (.pk) is required for JaaS JWT signing.'
    );
  }

  // Handle escaped newlines in environment variable (e.g., in .env or cloud secret managers)
  if (privateKey.includes('\\n')) {
    privateKey = privateKey.replace(/\\n/g, '\n');
  }

  const isInstructor = user.role === 'instructor';
  const now = Math.floor(Date.now() / 1000);

  // JWT Header conforming to 8x8 JaaS specification
  const header: jwt.JwtHeader = {
    alg: 'RS256',
    typ: 'JWT',
    kid: apiKeyId,
  };

  // JWT Payload conforming to 8x8 JaaS specification
  const payload = {
    aud: 'jitsi',
    iss: 'chat',
    iat: now,
    exp: now + 10800, // 3 hours validity
    nbf: now - 10,
    sub: appId,
    room: '*', // Or specific room name like `sanitizeRoomName(roomName, appId)`
    context: {
      features: {
        livestreaming: isInstructor,
        recording: isInstructor,
        transcription: false,
      },
      user: {
        id: user.id,
        name: isInstructor ? `${user.name} (Host)` : user.name,
        email: user.email,
        avatar: user.avatarUrl || '',
        moderator: isInstructor, // Critical: True for instructor, False for student
      },
    },
  };

  return jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    header,
  });
}
