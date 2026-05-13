import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Internship Tracker',
  description: 'Oportunidades de internship — Ingeniería Telemática 2027',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body className="bg-bg min-h-screen">{children}</body>
    </html>
  )
}
