'use client'
import { useEffect, useState, useCallback } from 'react'
import { supabase, Company, Opening, NewsItem } from '@/lib/supabase'
import CompanyTable from '@/app/components/CompanyTable'
import OpeningsPanel from '@/app/components/OpeningsPanel'
import NewsPanel from '@/app/components/NewsPanel'
import StatsBar from '@/app/components/StatsBar'
import Header from '@/app/components/Header'
import { Building2, Radio, Newspaper } from 'lucide-react'

export default function Home() {
  const [companies, setCompanies] = useState<Company[]>([])
  const [openings, setOpenings] = useState<Opening[]>([])
  const [news, setNews] = useState<NewsItem[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'companies'|'openings'|'news'>('companies')

  const fetchAll = useCallback(async () => {
    const [{ data: c }, { data: o }, { data: n }] = await Promise.all([
      supabase.from('companies').select('*').order('name'),
      supabase.from('openings').select('*, companies(name, flag)').eq('is_active', true).order('found_at', { ascending: false }),
      supabase.from('news').select('*, companies(name, flag)').order('created_at', { ascending: false }).limit(50),
    ])
    if (c) setCompanies(c)
    if (o) setOpenings(o as Opening[])
    if (n) setNews(n as NewsItem[])
    setLoading(false)
  }, [])

  useEffect(() => {
    fetchAll()
    const openingsSub = supabase.channel('openings-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'openings' }, fetchAll)
      .subscribe()
    const newsSub = supabase.channel('news-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'news' }, fetchAll)
      .subscribe()
    const companiesSub = supabase.channel('companies-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'companies' }, fetchAll)
      .subscribe()
    return () => {
      supabase.removeChannel(openingsSub)
      supabase.removeChannel(newsSub)
      supabase.removeChannel(companiesSub)
    }
  }, [fetchAll])

  const tabs = [
    { key: 'companies' as const, label: 'Empresas', icon: Building2, count: companies.length },
    { key: 'openings'  as const, label: 'Vacantes abiertas', icon: Radio, count: openings.length },
    { key: 'news'      as const, label: 'Noticias', icon: Newspaper, count: news.length },
  ]

  return (
    <div className="min-h-screen bg-bg">
      <Header />
      <main className="max-w-[1400px] mx-auto px-6 py-8">

        {/* Page title */}
        <div className="mb-8">
          <h1 className="font-display font-bold text-3xl text-ink tracking-tight mb-1">
            Oportunidades 2027
          </h1>
          <p className="text-muted text-sm">
            Internships y primeros empleos para Ingeniería Telemática — IA, robótica, telecomunicaciones y más.
          </p>
        </div>

        <StatsBar companies={companies} openings={openings} news={news} />

        {/* Tabs */}
        <div className="flex gap-1 mb-6 border-b border-border">
          {tabs.map(tab => {
            const Icon = tab.icon
            return (
              <button key={tab.key} onClick={() => setActiveTab(tab.key)}
                className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium transition border-b-2 -mb-px ${
                  activeTab === tab.key
                    ? 'border-ink text-ink'
                    : 'border-transparent text-muted hover:text-ink'
                }`}>
                <Icon size={14}/>
                {tab.label}
                <span className={`text-xs px-1.5 py-0.5 rounded-full ${
                  activeTab === tab.key ? 'bg-ink text-white' : 'bg-subtle text-faint'
                }`}>{tab.count}</span>
              </button>
            )
          })}
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-64 text-muted">
            <div className="text-center">
              <div className="w-6 h-6 border-2 border-border-strong border-t-ink rounded-full animate-spin mx-auto mb-3"/>
              <p className="text-sm">Cargando...</p>
            </div>
          </div>
        ) : (
          <>
            {activeTab === 'companies' && <CompanyTable companies={companies}/>}
            {activeTab === 'openings'  && <OpeningsPanel openings={openings}/>}
            {activeTab === 'news'      && <NewsPanel news={news}/>}
          </>
        )}
      </main>
    </div>
  )
}
