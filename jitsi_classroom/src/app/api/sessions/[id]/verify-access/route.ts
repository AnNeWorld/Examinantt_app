import { NextRequest, NextResponse } from 'next/server';
import { getSessionById, verifyStudentEnrollment } from '../../../../../lib/sessions-store';

/**
 * POST /api/sessions/[id]/verify-access
 * Verifies if student has active batch enrollment / purchase to access the live class.
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await req.json();
    const { userId, userRole = 'student' } = body;

    if (!userId) {
      return NextResponse.json(
        { isAuthorized: false, message: 'User ID is required to verify enrollment.' },
        { status: 400 }
      );
    }

    const session = getSessionById(id);
    if (!session) {
      return NextResponse.json(
        { isAuthorized: false, message: 'Live class session not found.' },
        { status: 404 }
      );
    }

    const check = verifyStudentEnrollment(id, userId, userRole);

    return NextResponse.json({
      sessionId: id,
      userId,
      isAuthorized: check.isAuthorized,
      status: session.status,
      roomName: session.roomName,
      title: session.title,
      instructorName: session.instructorName,
      message: check.message || (check.isAuthorized ? 'Access granted' : 'Access denied'),
    });
  } catch (error: any) {
    console.error('[API verify-access] Error:', error);
    return NextResponse.json(
      { isAuthorized: false, message: error?.message || 'Verification error' },
      { status: 500 }
    );
  }
}
