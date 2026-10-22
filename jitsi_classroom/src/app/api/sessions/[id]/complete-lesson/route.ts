import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/sessions/[id]/complete-lesson
 * Triggered automatically when student watches >= 90% of a completed class replay.
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await req.json();
    const { studentId, completedAt } = body;

    console.log(
      `[API Complete Lesson] Student ${studentId} completed session ${id} at ${completedAt}`
    );

    // In production, update student course progress in your database (e.g. Prisma / MongoDB):
    // await db.studentCourseProgress.upsert({
    //   where: { studentId_lessonId: { studentId, lessonId: id } },
    //   update: { isCompleted: true, completedAt: new Date(completedAt) },
    //   create: { studentId, lessonId: id, isCompleted: true, completedAt: new Date(completedAt) },
    // });

    return NextResponse.json({
      success: true,
      message: 'Lesson marked as completed successfully.',
      sessionId: id,
      studentId,
      completedAt: completedAt || new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('[API Complete Lesson] Error:', error);
    return NextResponse.json(
      { error: error?.message || 'Failed to record completion' },
      { status: 500 }
    );
  }
}
