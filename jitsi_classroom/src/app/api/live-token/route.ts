import { NextRequest, NextResponse } from 'next/server';
import { generateJitsiToken, sanitizeRoomName } from '../../../lib/jitsi-jwt';
import { ClassroomUser } from '../../../types/classroom';
import { getSessionById, verifyStudentEnrollment } from '../../../lib/sessions-store';

/**
 * POST /api/live-token
 * Authenticates student, verifies classroom access, and returns authorized Jitsi room information:
 * - token: Signed RS256 JWT (if 8x8 JaaS configured)
 * - roomName: Sanitized room name (exact matching between web and mobile)
 * - domain: Jitsi domain ('8x8.vc', 'meet.jit.si', or custom self-hosted)
 * - serverUrl: Fully qualified URL (e.g. 'https://8x8.vc' or 'https://meet.jit.si')
 * - subject: Session title
 * - status: 'scheduled' | 'live' | 'completed'
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { sessionId, roomName, user } = body as {
      sessionId: string;
      roomName: string;
      user: ClassroomUser;
    };

    if (!sessionId || !user || !user.id || !user.role) {
      return NextResponse.json(
        { error: 'Missing required parameters: sessionId, user' },
        { status: 400 }
      );
    }

    const session = getSessionById(sessionId);
    const targetRoomName = roomName || session?.roomName || `examinantt-${sessionId}`;

    // 1. Verify student enrollment & permission
    const authCheck = verifyStudentEnrollment(sessionId, user.id, user.role);
    if (!authCheck.isAuthorized) {
      return NextResponse.json(
        { error: authCheck.message || 'You are not enrolled in this live class.' },
        { status: 403 }
      );
    }

    const domain = process.env.JITSI_DOMAIN || process.env.NEXT_PUBLIC_JITSI_DOMAIN || 'meet.jit.si';
    const appId = process.env.JAAS_APP_ID || process.env.NEXT_PUBLIC_JAAS_APP_ID || 'vpaas-magic-cookie-examinantt-app';
    const isJaaS = domain.toLowerCase().includes('8x8.vc');

    // Sanitized room name conforming to JaaS: <appId>/<roomName>
    const sanitizedRoom = sanitizeRoomName(targetRoomName, isJaaS ? appId : undefined);

    let token = '';
    const hasPrivateKey = !!process.env.JAAS_PRIVATE_KEY;

    if (isJaaS && hasPrivateKey) {
      try {
        token = generateJitsiToken({
          user,
          roomName: sanitizedRoom,
          appId,
        });
      } catch (tokenErr) {
        console.warn('[API /api/live-token] JaaS token generation failed, falling back:', tokenErr);
      }
    }

    const serverUrl = `https://${domain}`;

    return NextResponse.json({
      token,
      roomName: sanitizedRoom,
      domain,
      appId: isJaaS ? appId : '',
      serverUrl,
      subject: session?.title || 'Examinantt Live Lecture',
      status: session?.status || 'live',
      isLive: session?.status === 'live',
      startedAt: session?.startedAt,
    });
  } catch (error: any) {
    console.error('[API /api/live-token] Error generating JaaS JWT:', error);
    return NextResponse.json(
      { error: error?.message || 'Internal server error generating token' },
      { status: 500 }
    );
  }
}
