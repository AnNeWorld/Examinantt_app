import { NextRequest, NextResponse } from 'next/server';
import { getSessionById, patchSessionStatus, createOrUpdateSession } from '../../../../lib/sessions-store';
import { LiveSessionMetadata } from '../../../../types/classroom';

/**
 * GET /api/sessions/[id]
 * Returns session details.
 * Used by students' background polling mechanism (every 15-20s) to detect when class becomes live.
 */
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  let session = getSessionById(id);

  if (!session) {
    // Generate default session metadata for unknown IDs and register
    session = {
      id,
      courseId: 'course-default',
      courseTitle: 'Interactive Classroom',
      title: `Live Session #${id}`,
      instructorId: 'inst-default',
      instructorName: 'Lead Instructor',
      status: 'scheduled',
      roomName: `classroom-${id}`,
      durationMinutes: 60,
    };
    createOrUpdateSession(session);
  }

  return NextResponse.json(session);
}

/**
 * PATCH /api/sessions/[id]
 * Updates session lifecycle status: 'scheduled' -> 'live' -> 'completed',
 * recording URLs, startedAt, and endedAt timestamps.
 */
export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const body = await req.json();

  const newStatus = body.status;
  const updated = patchSessionStatus(id, newStatus, body);

  console.log(`[API /api/sessions/${id}] Session updated to status:`, updated.status);

  return NextResponse.json(updated);
}
