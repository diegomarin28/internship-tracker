import { ExternalLink } from 'lucide-react'
import { NewsItem } from '@/lib/supabase'
import { formatDistanceToNow } from 'date-fns'
import { es } from 'date-fns/locale'

const CAT_STYLES: Record<string, string> = {
  'internship_open': 'bg-green-50 text-green-700 border-green-200',
  'company_news':    'bg-blue-50 text-blue-700 border-blue-200',
  'sector_news':     'bg-purple-50 text-purple-700 border-purple-200',
}
const CAT_LABELS: Record<string, string> = {
  'internship_open': 'Internship abierto',
  'company_news':    'Novedad empresa',
  'sector_news':     'Sector tech',
}

export default function NewsPanel({ news }: { news: NewsItem[] }) {
  if (news.length === 0) {
    return (
      <div className="bg-card border border-border rounded-xl p-16 text-center">
        <h3 className="font-display font-semibold text-ink mb-1">Sin noticias todavía</h3>
        <p className="text-muted text-sm">El scanner cargará noticias del sector automáticamente.</p>
      </div>
    )
  }

  return (
    <div className="grid gap-3">
      {news.map(n => (
        <div key={n.id} className="bg-card border border-border rounded-xl p-5 hover:border-border-strong transition">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2 flex-wrap">
                {(n.companies as any)?.name && (
                  <span className="text-xs font-medium text-ink">{(n.companies as any).name}</span>
                )}
                <span className={`text-xs px-2 py-0.5 rounded-md border font-medium ${CAT_STYLES[n.category] || 'bg-subtle text-muted border-border'}`}>
                  {CAT_LABELS[n.category] || n.category}
                </span>
                {n.relevance_score > 7 && (
                  <span className="text-xs bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-md font-medium">Alta relevancia</span>
                )}
              </div>
              <h3 className="font-display font-semibold text-ink mb-1 leading-snug">{n.title}</h3>
              {n.summary && <p className="text-sm text-muted leading-relaxed">{n.summary}</p>}
              <div className="flex items-center gap-2 mt-2 text-xs text-faint">
                {n.source && <span>{n.source}</span>}
                <span>·</span>
                <span>{formatDistanceToNow(new Date(n.created_at), { addSuffix: true, locale: es })}</span>
              </div>
            </div>
            {n.url && (
              <a href={n.url} target="_blank" rel="noopener noreferrer"
                className="text-faint hover:text-ink transition flex-shrink-0 mt-1">
                <ExternalLink size={14} />
              </a>
            )}
          </div>
        </div>
      ))}
    </div>
  )
}
