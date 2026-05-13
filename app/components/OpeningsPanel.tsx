import { ExternalLink, MapPin, Clock } from 'lucide-react'
import { Opening } from '@/lib/supabase'
import { formatDistanceToNow } from 'date-fns'
import { es } from 'date-fns/locale'

export default function OpeningsPanel({ openings }: { openings: Opening[] }) {
  if (openings.length === 0) {
    return (
      <div className="bg-card border border-border rounded-xl p-16 text-center">
        <div className="w-10 h-10 bg-subtle rounded-xl flex items-center justify-center mx-auto mb-4">
          <ExternalLink size={18} className="text-muted" />
        </div>
        <h3 className="font-display font-semibold text-ink mb-1">Sin vacantes detectadas aún</h3>
        <p className="text-muted text-sm">Usá el botón "Buscar vacantes" para escanear las empresas de tu lista.</p>
      </div>
    )
  }

  return (
    <div className="grid gap-3">
      {openings.map(o => (
        <div key={o.id} className="bg-card border border-border rounded-xl p-5 hover:border-border-strong transition">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-sm font-medium text-ink">{(o.companies as any)?.name}</span>
                <span className="w-1 h-1 bg-border-strong rounded-full" />
                <span className="text-xs text-green-600 font-medium flex items-center gap-1">
                  <span className="w-1.5 h-1.5 bg-green-500 rounded-full inline-block" />
                  Abierta
                </span>
              </div>
              <h3 className="font-display font-semibold text-ink text-lg mb-2">{o.title}</h3>
              {o.location && (
                <div className="flex items-center gap-1 text-xs text-muted mb-2">
                  <MapPin size={11} />
                  <span>{o.location}</span>
                </div>
              )}
              {o.description && <p className="text-sm text-muted leading-relaxed">{o.description}</p>}
              {o.deadline && (
                <div className="flex items-center gap-1 text-xs text-amber-600 mt-3 font-medium">
                  <Clock size={11} />
                  <span>Deadline: {o.deadline}</span>
                </div>
              )}
            </div>
            <div className="flex flex-col items-end gap-3 flex-shrink-0">
              <span className="text-xs text-faint">
                {formatDistanceToNow(new Date(o.found_at), { addSuffix: true, locale: es })}
              </span>
              {o.url && (
                <a href={o.url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 bg-ink text-white hover:bg-ink/80 px-3 py-1.5 rounded-lg text-xs font-medium transition">
                  <ExternalLink size={11} /> Aplicar
                </a>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
