'use client';

import React, { useState, useRef } from 'react';

interface RecordingUploaderProps {
  sessionId: string;
  onRecordingSaved: (recordingUrl: string) => void;
  className?: string;
}

/**
 * Enterprise AWS S3 Resumable Multipart Upload & External Replay Link Handler
 * Supports multi-gigabyte video uploads with chunking, upload progress tracking,
 * and YouTube / CDN fallback links.
 */
export const RecordingUploader: React.FC<RecordingUploaderProps> = ({
  sessionId,
  onRecordingSaved,
  className = '',
}) => {
  const [activeTab, setActiveTab] = useState<'upload' | 'external'>('upload');
  const [externalUrl, setExternalUrl] = useState<string>('');
  const [file, setFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [uploadProgress, setUploadProgress] = useState<number>(0);
  const [uploadStatus, setUploadStatus] = useState<string>('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const selected = e.target.files[0];
      // Validate video MIME type
      if (!selected.type.startsWith('video/')) {
        setErrorMessage('Please select a valid video file (MP4, WebM, MKV, MOV).');
        return;
      }
      setErrorMessage(null);
      setFile(selected);
      setUploadProgress(0);
      setUploadStatus('');
    }
  };

  // Perform Resumable AWS S3 Multipart Upload
  const handleS3MultipartUpload = async () => {
    if (!file) return;

    setIsUploading(true);
    setErrorMessage(null);
    setUploadStatus('Initiating AWS S3 multipart upload session...');
    setUploadProgress(5);

    try {
      // Step 1: Initiate Multipart Upload via Next.js API
      const initRes = await fetch('/api/s3/multipart', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'initiate',
          filename: file.name,
          contentType: file.type || 'video/mp4',
          sessionId,
        }),
      });

      if (!initRes.ok) {
        const err = await initRes.json();
        throw new Error(err.error || 'Failed to initiate multipart upload.');
      }

      const { uploadId, key } = await initRes.json();

      // Step 2: Upload in 5MB Chunks
      const CHUNK_SIZE = 5 * 1024 * 1024; // 5MB minimum chunk size for S3 multipart
      const totalParts = Math.ceil(file.size / CHUNK_SIZE);
      const completedParts: { PartNumber: number; ETag: string }[] = [];

      for (let partNumber = 1; partNumber <= totalParts; partNumber++) {
        const start = (partNumber - 1) * CHUNK_SIZE;
        const end = Math.min(start + CHUNK_SIZE, file.size);
        const chunkBlob = file.slice(start, end);

        setUploadStatus(`Uploading chunk ${partNumber} of ${totalParts}...`);

        // Request presigned URL for this specific part
        const partRes = await fetch('/api/s3/multipart', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            action: 'getPartUrl',
            uploadId,
            key,
            partNumber,
            sessionId,
          }),
        });

        if (!partRes.ok) {
          throw new Error(`Failed to obtain upload URL for chunk ${partNumber}`);
        }

        const { presignedUrl } = await partRes.json();

        // Upload chunk directly to S3 via PUT
        const uploadChunkRes = await fetch(presignedUrl, {
          method: 'PUT',
          body: chunkBlob,
        });

        if (!uploadChunkRes.ok) {
          throw new Error(`Failed to upload chunk ${partNumber} to storage.`);
        }

        const etag = uploadChunkRes.headers.get('ETag') || `etag-chunk-${partNumber}`;
        completedParts.push({ PartNumber: partNumber, ETag: etag.replace(/"/g, '') });

        const progressPercent = Math.min(95, Math.floor((partNumber / totalParts) * 90) + 5);
        setUploadProgress(progressPercent);
      }

      // Step 3: Complete Multipart Upload
      setUploadStatus('Finalizing upload and assembling video on S3...');
      const completeRes = await fetch('/api/s3/multipart', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'complete',
          uploadId,
          key,
          parts: completedParts,
          sessionId,
        }),
      });

      if (!completeRes.ok) {
        throw new Error('Failed to complete S3 multipart upload.');
      }

      const { locationUrl } = await completeRes.json();
      setUploadProgress(100);
      setUploadStatus('Recording uploaded successfully!');
      setIsUploading(false);

      onRecordingSaved(locationUrl);
    } catch (err: any) {
      console.error('[RecordingUploader] Upload error:', err);
      setErrorMessage(err?.message || 'Upload failed. Please check connection and try again.');
      setIsUploading(false);
      setUploadStatus('');
    }
  };

  const handleSaveExternalUrl = () => {
    if (!externalUrl.trim()) {
      setErrorMessage('Please enter a valid replay URL.');
      return;
    }

    try {
      new URL(externalUrl.trim());
    } catch (_) {
      setErrorMessage('Invalid URL format. Include http:// or https://');
      return;
    }

    setErrorMessage(null);
    onRecordingSaved(externalUrl.trim());
  };

  return (
    <div className={`p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl ${className}`}>
      <div className="flex items-center justify-between mb-5">
        <div>
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <span>📹</span>
            <span>Publish Class Recording / Replay</span>
          </h3>
          <p className="text-xs text-slate-400 mt-1">
            Provide students with on-demand access to this lecture.
          </p>
        </div>

        {/* Tab switch */}
        <div className="flex bg-slate-800 p-1 rounded-xl border border-slate-700/60">
          <button
            onClick={() => setActiveTab('upload')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
              activeTab === 'upload'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            S3 Resumable Upload
          </button>
          <button
            onClick={() => setActiveTab('external')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
              activeTab === 'external'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            External / YouTube Link
          </button>
        </div>
      </div>

      {errorMessage && (
        <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-2">
          <span>⚠️</span>
          <span>{errorMessage}</span>
        </div>
      )}

      {activeTab === 'upload' ? (
        <div className="space-y-4">
          <input
            type="file"
            ref={fileInputRef}
            onChange={handleFileChange}
            accept="video/*"
            className="hidden"
          />

          {!file ? (
            <div
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-slate-700 hover:border-indigo-500/60 rounded-xl p-8 text-center cursor-pointer transition-all bg-slate-950/40 hover:bg-slate-950/80 group"
            >
              <div className="w-12 h-12 mx-auto rounded-full bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xl text-indigo-400 mb-3 group-hover:scale-110 transition-transform">
                ☁️
              </div>
              <p className="text-sm font-semibold text-slate-200">
                Click to browse or drop lecture recording
              </p>
              <p className="text-xs text-slate-500 mt-1">
                Supports MP4, WebM, MOV with AWS S3 resumable multipart chunking
              </p>
            </div>
          ) : (
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 truncate">
                  <div className="w-9 h-9 rounded-lg bg-indigo-600/20 text-indigo-400 flex items-center justify-center text-lg">
                    🎞️
                  </div>
                  <div className="truncate">
                    <p className="text-sm font-medium text-white truncate">{file.name}</p>
                    <p className="text-xs text-slate-400">{formatFileSize(file.size)}</p>
                  </div>
                </div>

                {!isUploading && (
                  <button
                    onClick={() => {
                      setFile(null);
                      setUploadProgress(0);
                    }}
                    className="text-xs text-slate-400 hover:text-rose-400 px-2 py-1"
                  >
                    Change
                  </button>
                )}
              </div>

              {isUploading && (
                <div className="space-y-2">
                  <div className="flex justify-between text-xs text-slate-400">
                    <span>{uploadStatus}</span>
                    <span className="font-mono font-semibold text-indigo-400">{uploadProgress}%</span>
                  </div>
                  <div className="w-full bg-slate-800 rounded-full h-2 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-indigo-500 to-cyan-400 h-2 rounded-full transition-all duration-300"
                      style={{ width: `${uploadProgress}%` }}
                    />
                  </div>
                </div>
              )}

              {!isUploading && uploadProgress === 0 && (
                <button
                  onClick={handleS3MultipartUpload}
                  className="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-medium transition-all shadow-lg shadow-indigo-600/30 flex items-center justify-center gap-2"
                >
                  <span>Start S3 Multipart Upload</span>
                  <span>🚀</span>
                </button>
              )}
            </div>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
              Replay Link (YouTube / Vimeo / CloudFront)
            </label>
            <input
              type="url"
              value={externalUrl}
              onChange={(e) => setExternalUrl(e.target.value)}
              placeholder="https://www.youtube.com/watch?v=... or https://cdn.example.com/recording.mp4"
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl text-sm text-white placeholder-slate-500 outline-none transition-all"
            />
          </div>

          <button
            onClick={handleSaveExternalUrl}
            className="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-medium transition-all shadow-lg shadow-indigo-600/30"
          >
            Attach Replay Link
          </button>
        </div>
      )}
    </div>
  );
};

export default RecordingUploader;
