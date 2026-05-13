import { Company, Opening, NewsItem } from '@/lib/supabase'
import { Building2, Zap, Radio, AlertTriangle, Newspaper } from 'lucide-react'

export default function StatsBar({ companies, openings, news }: {
  companies: Company[]
  openings: Opening[]
  news: NewsItem[]
}) {
  const urgentCount = companies.filter(c => c.apply_year_start <= 2026).length
  const startupCount = companies.filter(c => c.is_startup).length

  const stats = [
    { label: 'Empresas', value: companies.length, icon: Building2, color: 'text-ink' },
    { label: 'Startups', value: startupCount, icon: Zap, color: 'text-purple-600' },
    { label: 'Vacantes abiertas', value: openings.length, icon: Radio, color: 'text-green-600' },
    { label: 'Aplican en 2026', value: urgentCount, icon: AlertTriangle, color: 'text-amber-600' },
    { label: 'Noticias', value: news.length, icon: Newspaper, color: 'text-blue-600' },
  ]

  return (
    <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-8">
      {stats.map(s => {
        const Icon = s.icon
        return (
          <div key={s.label} className="bg-card border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-2">
              <Icon size={14} className={s.color} />
            </div>
            <div className="font-display font-bold text-2xl text-ink">{s.value}</div>
            <div className="text-xs text-muted mt-0.5">{s.label}</div>
          </div>
        )
      })}
    </div>
  )
}
