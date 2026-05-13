'use client'
import { useState } from 'react'
import { RefreshCw, Bell, Wifi } from 'lucide-react'

export default function Header() {
  const [scanning, setScanning] = useState(false)
  const [msg, setMsg] = useState('')

  const triggerScan = async () => {
    setScanning(true)
    setMsg('')
    try {
      const res = await fetch('/api/cron/scan', { method: 'POST' })
      const data = await res.json()
      setMsg(data.message || 'Completado')
    } catch {
      setMsg('Error al conectar')
    }
    setScanning(false)
    setTimeout(() => setMsg(''), 5000)
  }

  return (
    <header className="border-b border-border bg-card sticky top-0 z-50">
      <div className="max-w-[1400px] mx-auto px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-7 h-7 bg-ink rounded-md flex items-center justify-center">
            <span className="text-white text-xs font-display font-bold">IT</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-display font-semibold text-ink text-sm tracking-tight">Internship Tracker</span>
            <span className="text-faint text-xs">/ Telemática 2027</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {msg && (
            <span className={`text-xs mr-1 ${msg.includes('Error') ? 'text-red-500' : 'text-green-600'}`}>
              {msg}
            </span>
          )}
          <div className="flex items-center gap-1.5 text-xs text-green-600 bg-green-50 border border-green-200 px-2.5 py-1 rounded-full">
            <Wifi size={10} />
            <span>En vivo</span>
          </div>
          <button
            onClick={triggerScan}
            disabled={scanning}
            className="flex items-center gap-1.5 text-xs bg-ink text-white hover:bg-ink/80 disabled:opacity-40 px-3 py-1.5 rounded-lg transition font-medium"
          >
            <RefreshCw size={11} className={scanning ? 'animate-spin' : ''} />
            {scanning ? 'Buscando...' : 'Buscar vacantes'}
          </button>
          <div className="hidden sm:flex items-center gap-1.5 text-xs text-muted bg-subtle border border-border px-3 py-1.5 rounded-lg">
            <Bell size={11} />
            <span>diegomarinarnoletti@gmail.com</span>
          </div>
        </div>
      </div>
    </header>
  )
}
