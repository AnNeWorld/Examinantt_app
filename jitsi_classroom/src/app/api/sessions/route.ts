import { NextRequest, NextResponse } from 'next/server';
import { getAllSessions, createOrUpdateSession } from '../../../lib/sessions-store';
import { LiveSessionMetadata } from '../../../types/classroom';

/**
 * GET /api/sessions
 * Returns list of all live classes.
 * Supports query params:
 * - ?courseId=...
 * - ?batchId=...
 * - ?status=live|scheduled|completed
 */
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const courseId = searchParams.get('courseId') || undefined;
    const batchId = searchParams.get('batchId') || undefined;
    const status = searchParams.get('status') || undefined;

    const sessions = getAllSessions({ courseId, batchId, status });
    return NextResponse.json({
      success: true,
      count: sessions.length,
      sessions,
    });
  } catch (error: any) {
    console.error('[API /api/sessions] Error fetching sessions:', error);
    return NextResponse.json(
      { success: false, error: error?.message || 'Failed to fetch live classes' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/sessions
 * Creates or registers a new live class session on the website/backend.
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { id, title, roomName, courseId, instructorName, scheduledStartTime, durationMinutes } = body;

    if (!id || !title || !roomName) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields: id, title, roomName' },
        { status: 400 }
      );
    }

    const newSession: LiveSessionMetadata = {
      id,
      courseId: courseId || 'course-default',
      courseTitle: body.courseTitle || 'Live Batch Course',
      title,
      description: body.description || '',
      instructorId: body.instructorId || 'inst-1',
      instructorName: instructorName || 'Examinantt Faculty',
      status: body.status || 'scheduled',
      scheduledStartTime: scheduledStartTime || new Date().toISOString(),
      durationMinutes: durationMinutes || 60,
      roomName,
      fallbackProvider: body.fallbackProvider || 'jitsi',
    };

    const saved = createOrUpdateSession(newSession);
    return NextResponse.json({
      success: true,
      message: 'Live session registered successfully',
      session: saved,
    });
  } catch (error: any) {
    console.error('[API /api/sessions] Error creating session:', error);
    return NextResponse.json(
      { success: false, error: error?.message || 'Failed to create session' },
      { status: 500 }
    );
  }
}
