import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/s3/multipart
 * Backend endpoint for AWS S3 Resumable Multipart Uploads:
 * - initiate: Creates S3 multipart upload session
 * - getPartUrl: Returns presigned URL for a specific 5MB+ chunk
 * - complete: Assembles all uploaded chunks into final S3 object
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { action, filename, contentType, sessionId, uploadId, key, partNumber, parts } = body;

    const bucketName = process.env.AWS_S3_BUCKET_NAME || 'examinantt-recordings';
    const region = process.env.AWS_REGION || 'us-east-1';
    const hasAwsCreds = !!(process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY);

    // =========================================================================
    // 1. ACTION: INITIATE
    // =========================================================================
    if (action === 'initiate') {
      const sanitizedFilename = (filename || 'recording.mp4').replace(/[^a-zA-Z0-9._-]/g, '_');
      const objectKey = `recordings/${sessionId}/${Date.now()}-${sanitizedFilename}`;

      if (hasAwsCreds) {
        // AWS SDK implementation
        const { S3Client, CreateMultipartUploadCommand } = await import('@aws-sdk/client-s3');
        const s3 = new S3Client({ region });
        const command = new CreateMultipartUploadCommand({
          Bucket: bucketName,
          Key: objectKey,
          ContentType: contentType || 'video/mp4',
        });
        const response = await s3.send(command);
        return NextResponse.json({
          uploadId: response.UploadId,
          key: objectKey,
        });
      } else {
        // Dev fallback simulation
        const mockUploadId = `mock-upload-${Date.now()}-${Math.random().toString(36).substring(7)}`;
        return NextResponse.json({
          uploadId: mockUploadId,
          key: objectKey,
        });
      }
    }

    // =========================================================================
    // 2. ACTION: GET PART PRESIGNED URL
    // =========================================================================
    if (action === 'getPartUrl') {
      if (!uploadId || !key || !partNumber) {
        return NextResponse.json(
          { error: 'Missing uploadId, key, or partNumber' },
          { status: 400 }
        );
      }

      if (hasAwsCreds) {
        const { S3Client, UploadPartCommand } = await import('@aws-sdk/client-s3');
        const { getSignedUrl } = await import('@aws-sdk/s3-request-presigner');
        const s3 = new S3Client({ region });
        const command = new UploadPartCommand({
          Bucket: bucketName,
          Key: key,
          UploadId: uploadId,
          PartNumber: Number(partNumber),
        });
        const presignedUrl = await getSignedUrl(s3, command, { expiresIn: 3600 });
        return NextResponse.json({ presignedUrl });
      } else {
        // Dev fallback: returns a dummy local endpoint
        const host = req.headers.get('host') || 'localhost:3000';
        const protocol = host.includes('localhost') ? 'http' : 'https';
        const mockUrl = `${protocol}://${host}/api/s3/multipart?mockChunk=${partNumber}`;
        return NextResponse.json({ presignedUrl: mockUrl });
      }
    }

    // =========================================================================
    // 3. ACTION: COMPLETE
    // =========================================================================
    if (action === 'complete') {
      if (!uploadId || !key || !parts) {
        return NextResponse.json(
          { error: 'Missing uploadId, key, or parts array' },
          { status: 400 }
        );
      }

      let locationUrl = `https://${bucketName}.s3.${region}.amazonaws.com/${key}`;

      if (hasAwsCreds) {
        const { S3Client, CompleteMultipartUploadCommand } = await import('@aws-sdk/client-s3');
        const s3 = new S3Client({ region });
        const command = new CompleteMultipartUploadCommand({
          Bucket: bucketName,
          Key: key,
          UploadId: uploadId,
          MultipartUpload: {
            Parts: parts,
          },
        });
        const response = await s3.send(command);
        locationUrl = response.Location || locationUrl;
      }

      return NextResponse.json({
        success: true,
        locationUrl,
        key,
      });
    }

    return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
  } catch (error: any) {
    console.error('[API S3 Multipart] Error:', error);
    return NextResponse.json(
      { error: error?.message || 'S3 Multipart operation failed' },
      { status: 500 }
    );
  }
}

/**
 * PUT /api/s3/multipart
 * Catch mock chunk uploads during development when AWS credentials are not configured.
 */
export async function PUT(req: NextRequest) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      ETag: `"mock-etag-${Date.now()}"`,
    },
  });
}
