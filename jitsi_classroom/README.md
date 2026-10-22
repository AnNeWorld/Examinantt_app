# Enterprise Live Virtual Classroom (Jitsi Meet / 8x8 JaaS)

A complete, production-grade enterprise Live Classroom module built with **Next.js (React TypeScript)**, **Tailwind CSS**, **Jitsi External API (`window.JitsiMeetExternalAPI`)**, and **8x8 JaaS (`8x8.vc`)**.

---

## 🌟 Key Features

### 1. Secure RSA-256 JWT Authentication (`/api/live-token`)
- Signs an RSA-256 JWT token using an 8x8 JaaS private key (`.pk`).
- Configures token header (`kid: <JAAS_API_KEY_ID>`) and payload conforming to the 8x8 JaaS specification:
  - `sub`: JaaS App ID.
  - `room`: Sanitized room name (`<JAAS_APP_ID>/<sanitized_name>`).
  - `context.user.moderator`: `true` for Instructors, `false` for Students.
  - `context.features`: Livestreaming & recording permitted only for instructors.
- Expiration set to 3 hours with 10-second `nbf` leeway.

### 2. Core Player Component (`JitsiPlayer.tsx`)
- **Dynamic Script Loading**: Safely loads and deduplicates `https://8x8.vc/<appId>/external_api.js` or `https://meet.jit.si/external_api.js`.
- **Role-Based Toolbars**:
  - **Instructor Toolbar**: `['microphone', 'camera', 'desktop', 'chat', 'raisehand', 'participants-pane', 'tileview', 'fullscreen', 'security', 'mute-everyone', 'hangup']`
  - **Student Toolbar**: `['microphone', 'camera', 'chat', 'raisehand', 'tileview', 'fullscreen', 'hangup']`
- **Strict Security Overrides (`configOverwrite`)**:
  - `startWithAudioMuted: !isInstructor` (students enter muted)
  - `startWithVideoMuted: !isInstructor` (students enter without video)
  - `prejoinPageEnabled: false` (bypasses prejoin screen)
  - `disableDeepLinking: true` (keeps users inside web app)
  - `remoteVideoMenu.disableKick: !isInstructor` (students cannot kick users)
  - `remoteVideoMenu.disableGrantModerator: !isInstructor` (students cannot grant moderator status)
  - `disableRemoteMute: !isInstructor` (students cannot mute peers)
  - `p2p.enabled: false` (routes through Jitsi Videobridge SFU for stability)
- **Moderator Self-Healing Safeguard (Edge-Case Protection)**:
  - Listens to `participantRoleChanged`.
  - If a student client detects it was mistakenly promoted to `moderator` (e.g., host briefly disconnected), it scans participants for the Host (`(Host)` in displayName or instructor ID) and immediately executes:
    ```ts
    api.executeCommand('grantModerator', hostId);
    ```

### 3. Session Lifecycle State Machine (`VirtualClassroom.tsx`)
1. **Not Scheduled**:
   - Clean empty state card; no active meeting links.
2. **Scheduled**:
   - **Instructor**: "Start Class Now" button; updates DB status to `live`, records `startedAt`, and launches player.
   - **Student**: "Waiting for Instructor" state with gentle background polling every 20 seconds. Automatically auto-transitions to the live room once the instructor starts.
3. **Live**:
   - Synchronized server-side elapsed timer (`SessionTimer.tsx`) computed from `startedAt`.
   - **Instructor**: "End for All" (`endConference`) forcefully terminates room; "Leave Room" leaves locally while keeping room open for students.
   - **Student**: "Leave Class" (`hangup`) leaves locally with instant rejoin option while session remains live.
4. **Completed**:
   - **Instructor**: AWS S3 Resumable Multipart Upload (`RecordingUploader.tsx`) or YouTube / Vimeo external link.
   - **Student**: Embedded replay player (`ReplayPlayer.tsx`) with automated 90% progress tracking that automatically marks the lesson completed.

### 4. Admin & Fallbacks (`FallbackMeetingView.tsx`)
- Automatic room name sanitization (`lowercase-alphanumeric-hyphen`).
- Fallback support for **Zoom**, **Google Meet**, and **YouTube Live Broadcasts**.

---

## 🚀 Quick Start

### 1. Installation
```bash
cd jitsi_classroom
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env.local`:
```bash
cp .env.example .env.local
```
Fill in your 8x8 JaaS credentials:
- `JAAS_APP_ID`: Your JaaS App ID (e.g. `vpaas-magic-cookie-xxx`)
- `JAAS_API_KEY_ID`: Your JaaS API Key ID
- `JAAS_PRIVATE_KEY`: Your RSA private key string

### 3. Run Dev Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to view the interactive test dashboard where you can toggle between Instructor/Student modes and cycle through all 4 lifecycle states.

---

## 📁 File Structure

```
jitsi_classroom/
├── .env.example
├── package.json
├── tsconfig.json
├── tailwind.config.js
├── postcss.config.js
└── src/
    ├── types/
    │   └── classroom.ts                  # Domain interfaces & types
    ├── lib/
    │   └── jitsi-jwt.ts                  # RSA-256 JWT generator & room sanitizer
    ├── components/
    │   ├── JitsiPlayer.tsx               # Core Jitsi external API wrapper
    │   ├── SessionTimer.tsx              # Server-synchronized live timer
    │   ├── RecordingUploader.tsx         # S3 multipart resumable uploader
    │   ├── ReplayPlayer.tsx              # Replay player with 90% progress tracker
    │   ├── FallbackMeetingView.tsx       # Zoom / Meet / YouTube Live fallbacks
    │   └── VirtualClassroom.tsx          # 4-state lifecycle orchestrator
    └── app/
        ├── layout.tsx
        ├── page.tsx                      # Interactive demo test harness
        ├── globals.css
        └── api/
            ├── live-token/route.ts       # Secure JWT token generator
            ├── sessions/[id]/
            │   ├── route.ts              # Session polling & status updates
            │   └── complete-lesson/route.ts # 90% completion tracker API
            └── s3/multipart/route.ts     # S3 resumable multipart upload API
```
