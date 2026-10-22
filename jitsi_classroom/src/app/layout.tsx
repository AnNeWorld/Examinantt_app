import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Examinantt - Enterprise Live Classroom (Jitsi Meet / 8x8 JaaS)',
  description: 'Production-grade enterprise virtual classroom with role-based moderation, RSA-256 JWT security, and post-class recordings.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-slate-950 text-slate-100 antialiased font-sans min-h-screen">
        {children}
      </body>
    </html>
  );
}
