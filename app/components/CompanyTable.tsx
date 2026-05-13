'use client'
import { useState, useMemo } from 'react'
import { ExternalLink, Linkedin, ChevronUp, ChevronDown, X, DollarSign, MapPin, BookOpen, Code2, ArrowUpRight, Building2, Zap } from 'lucide-react'
import { Company } from '@/lib/supabase'
import DiffBadge from './DiffBadge'

const AREAS = ['Todas las áreas','Automotriz / IA','Robótica / Automatización','IA Aplicada / Software',
  'Telecomunicaciones / Redes','Big Tech','Investigación Aplicada','Logística / IoT',
  'Aeroespacial / Defensa','Semiconductores / Chips']
const REGIONS = ['Todas las regiones','Europa','EEUU','Global']
const DIFFICULTIES = ['Cualquier dificultad','Baja','Baja-Media','Media','Media-Alta','Alta','Muy Alta']

type SortKey = 'name'|'region'|'area'|'apply_month_start'|'entry_difficulty'|'work_difficulty'|'salary_max_usd'

const DIFF_ORDER: Record<string,number> = {
  'Baja':1,'Baja-Media':2,'Media':3,'Media-Alta':4,'Alta':5,'Muy Alta':6
}

const DIFF_EXPLAIN: Record<string,string> = {
  'Baja': 'Proceso simple, CV + entrevista de fit. Muy accesible para estudiantes internacionales.',
  'Baja-Media': 'Proceso estándar con una o dos entrevistas técnicas básicas.',
  'Media': 'Entrevistas técnicas de nivel intermedio. Requiere preparación pero es alcanzable.',
  'Media-Alta': 'Entrevistas técnicas sólidas. Conviene practicar algoritmos y proyectos previos.',
  'Alta': 'Proceso competitivo con múltiples rondas técnicas. Necesitás un perfil fuerte.',
  'Muy Alta': 'Proceso muy exigente con LeetCode, system design y portfolio técnico destacado.',
}

const WORK_EXPLAIN: Record<string,string> = {
  'Media': 'Proyectos acotados con mucho soporte. Buen lugar para aprender desde cero.',
  'Media-Alta': 'Trabajo real en equipos, con cierta autonomía. Aprendés rápido.',
  'Alta': 'Expectativas altas. Trabajás en código de producción con impacto real desde el día 1.',
  'Muy Alta': 'Ritmo intenso, tecnología de punta, equipo muy senior. Curva de aprendizaje empinada.',
}

export default function CompanyTable({ companies }: { companies: Company[] }) {
  const [search, setSearch] = useState('')
  const [region, setRegion] = useState('Todas las regiones')
  const [area, setArea] = useState('Todas las áreas')
  const [diff, setDiff] = useState('Cualquier dificultad')
  const [onlyStartups, setOnlyStartups] = useState(false)
  const [sortKey, setSortKey] = useState<SortKey>('name')
  const [sortAsc, setSortAsc] = useState(true)
  const [selected, setSelected] = useState<Company|null>(null)

  const filtered = useMemo(() => {
    let rows = companies.filter(c => {
      if (search && !c.name.toLowerCase().includes(search.toLowerCase()) &&
          !c.note?.toLowerCase().includes(search.toLowerCase()) &&
          !c.area.toLowerCase().includes(search.toLowerCase())) return false
      if (region !== 'Todas las regiones' && c.region !== region) return false
      if (area !== 'Todas las áreas' && c.area !== area) return false
      if (diff !== 'Cualquier dificultad' && c.entry_difficulty !== diff) return false
      if (onlyStartups && !c.is_startup) return false
      return true
    })
    rows.sort((a,b) => {
      let av: string|number, bv: string|number
      if (sortKey === 'entry_difficulty' || sortKey === 'work_difficulty') {
        av = DIFF_ORDER[a[sortKey]] || 0
        bv = DIFF_ORDER[b[sortKey]] || 0
      } else {
        av = a[sortKey] as string|number
        bv = b[sortKey] as string|number
        if (typeof av === 'string') av = av.toLowerCase()
        if (typeof bv === 'string') bv = bv.toLowerCase()
      }
      if (av < bv) return sortAsc ? -1 : 1
      if (av > bv) return sortAsc ? 1 : -1
      return 0
    })
    return rows
  }, [companies, search, region, area, diff, onlyStartups, sortKey, sortAsc])

  const sort = (key: SortKey) => {
    if (sortKey === key) setSortAsc(p => !p)
    else { setSortKey(key); setSortAsc(true) }
  }

  const Th = ({ k, label }: { k: SortKey; label: string }) => (
    <th onClick={() => sort(k)}
      className="px-4 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider cursor-pointer hover:text-ink select-none whitespace-nowrap transition">
      <span className="flex items-center gap-1">
        {label}
        {sortKey === k ? (sortAsc ? <ChevronUp size={10}/> : <ChevronDown size={10}/>) : null}
      </span>
    </th>
  )

  return (
    <div>
      {/* Filters */}
      <div className="flex flex-wrap gap-2 mb-5">
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Buscar empresa, área, tecnología..."
          className="bg-card border border-border rounded-lg px-3 py-2 text-sm text-ink placeholder-faint focus:outline-none focus:border-border-strong flex-1 min-w-[200px] transition" />
        {[
          { val: region, set: setRegion, options: REGIONS },
          { val: area,   set: setArea,   options: AREAS },
          { val: diff,   set: setDiff,   options: DIFFICULTIES },
        ].map((f,i) => (
          <select key={i} value={f.val} onChange={e => f.set(e.target.value)}
            className="bg-card border border-border rounded-lg px-3 py-2 text-sm text-ink focus:outline-none focus:border-border-strong cursor-pointer transition">
            {f.options.map(o => <option key={o}>{o}</option>)}
          </select>
        ))}
        <button onClick={() => setOnlyStartups(p => !p)}
          className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium transition border ${
            onlyStartups
              ? 'bg-ink text-white border-ink'
              : 'bg-card text-muted border-border hover:border-border-strong hover:text-ink'
          }`}>
          <Zap size={13} />
          Solo startups
        </button>
        <span className="text-xs text-faint self-center">{filtered.length} empresas</span>
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="border-b border-border bg-subtle/50">
              <tr>
                <Th k="name" label="Empresa" />
                <Th k="region" label="Región" />
                <Th k="area" label="Área" />
                <Th k="apply_month_start" label="Cuándo aplicar" />
                <Th k="salary_max_usd" label="Salario est." />
                <Th k="entry_difficulty" label="Ingreso" />
                <Th k="work_difficulty" label="Trabajo" />
                <th className="px-4 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">Links</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.map(c => (
                <tr key={c.id} onClick={() => setSelected(c)}
                  className="hover:bg-subtle/50 cursor-pointer transition group">
                  <td className="px-4 py-3.5">
                    <div className="flex items-center gap-2.5">
                      <div className="w-7 h-7 bg-subtle border border-border rounded-lg flex items-center justify-center flex-shrink-0 text-sm">
                        {c.flag}
                      </div>
                      <div>
                        <div className="font-medium text-ink text-sm group-hover:text-blue-600 transition flex items-center gap-1">
                          {c.name}
                          {c.is_startup && (
                            <span className="text-purple-500"><Zap size={11} /></span>
                          )}
                        </div>
                        <div className="text-xs text-faint">{c.city}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-xs text-muted">{c.region}</td>
                  <td className="px-4 py-3.5">
                    <span className="text-xs text-muted bg-subtle border border-border px-2 py-0.5 rounded-md">{c.area}</span>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className={`text-xs font-medium ${c.apply_year_start <= 2026 ? 'text-amber-600' : 'text-muted'}`}>
                      {c.apply_window}
                      {c.apply_year_start <= 2026 && <span className="ml-1 text-amber-500">!</span>}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-xs font-medium text-green-700">{c.salary_note}</td>
                  <td className="px-4 py-3.5"><DiffBadge level={c.entry_difficulty} /></td>
                  <td className="px-4 py-3.5"><DiffBadge level={c.work_difficulty} /></td>
                  <td className="px-4 py-3.5" onClick={e => e.stopPropagation()}>
                    <div className="flex gap-2">
                      {c.portal_url && (
                        <a href={c.portal_url} target="_blank" rel="noopener noreferrer"
                          className="text-faint hover:text-ink transition"><ExternalLink size={13}/></a>
                      )}
                      {c.linkedin_url && (
                        <a href={c.linkedin_url} target="_blank" rel="noopener noreferrer"
                          className="text-faint hover:text-blue-600 transition"><Linkedin size={13}/></a>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Detail modal */}
      {selected && (
        <div className="fixed inset-0 bg-ink/30 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={() => setSelected(null)}>
          <div className="bg-card border border-border rounded-2xl max-w-2xl w-full max-h-[88vh] overflow-y-auto shadow-2xl"
            onClick={e => e.stopPropagation()}>
            <div className="p-7">

              {/* Top bar */}
              <div className="flex items-start justify-between mb-5">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 bg-subtle border border-border rounded-xl flex items-center justify-center text-xl">
                    {selected.flag}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h2 className="font-display font-bold text-xl text-ink">{selected.name}</h2>
                      {selected.is_startup && (
                        <span className="text-xs bg-purple-50 text-purple-700 border border-purple-200 px-2 py-0.5 rounded-md font-medium flex items-center gap-1">
                          <Zap size={10}/> Startup
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-muted flex items-center gap-1 mt-0.5">
                      <MapPin size={11}/> {selected.city} · {selected.area}
                    </p>
                  </div>
                </div>
                <button onClick={() => setSelected(null)} className="text-faint hover:text-ink transition p-1">
                  <X size={18}/>
                </button>
              </div>

              {/* Description */}
              <p className="text-sm text-muted leading-relaxed mb-6 pb-6 border-b border-border">{selected.note}</p>

              {/* Salary + CoL */}
              <div className="grid grid-cols-2 gap-3 mb-5">
                <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                  <div className="flex items-center gap-1.5 text-green-700 mb-1">
                    <DollarSign size={13}/>
                    <span className="text-xs font-medium uppercase tracking-wide">Salario estimado</span>
                  </div>
                  <div className="font-display font-bold text-lg text-green-800">{selected.salary_note}</div>
                </div>
                <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                  <div className="flex items-center gap-1.5 text-amber-700 mb-1">
                    <MapPin size={13}/>
                    <span className="text-xs font-medium uppercase tracking-wide">Costo de vida — {selected.col_city}</span>
                  </div>
                  <div className="font-display font-bold text-lg text-amber-800">
                    ${selected.col_min_usd?.toLocaleString()}–${selected.col_max_usd?.toLocaleString()}/mes
                  </div>
                </div>
              </div>

              {/* Difficulty explained */}
              <div className="grid grid-cols-2 gap-3 mb-5">
                <div className="bg-subtle border border-border rounded-xl p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs text-muted font-medium uppercase tracking-wide">Dificultad de ingreso</span>
                    <DiffBadge level={selected.entry_difficulty}/>
                  </div>
                  <p className="text-xs text-muted leading-relaxed">
                    {DIFF_EXPLAIN[selected.entry_difficulty] || ''}
                  </p>
                </div>
                <div className="bg-subtle border border-border rounded-xl p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs text-muted font-medium uppercase tracking-wide">Dificultad del trabajo</span>
                    <DiffBadge level={selected.work_difficulty}/>
                  </div>
                  <p className="text-xs text-muted leading-relaxed">
                    {WORK_EXPLAIN[selected.work_difficulty] || ''}
                  </p>
                </div>
              </div>

              {/* Apply window */}
              <div className={`rounded-xl p-4 mb-5 border ${selected.apply_year_start <= 2026 ? 'bg-amber-50 border-amber-200' : 'bg-subtle border-border'}`}>
                <div className="flex items-center justify-between">
                  <div>
                    <div className="text-xs font-medium uppercase tracking-wide text-muted mb-0.5">Cuándo aplicar</div>
                    <div className={`font-display font-semibold text-lg ${selected.apply_year_start <= 2026 ? 'text-amber-700' : 'text-ink'}`}>
                      {selected.apply_window}
                    </div>
                  </div>
                  {selected.apply_year_start <= 2026 && (
                    <span className="text-xs bg-amber-100 text-amber-700 border border-amber-300 px-3 py-1 rounded-full font-medium">
                      Aplica antes — 2026
                    </span>
                  )}
                </div>
              </div>

              {/* Requirements */}
              {selected.requirements?.length > 0 && (
                <div className="mb-4">
                  <div className="flex items-center gap-1.5 text-blue-600 mb-2">
                    <BookOpen size={13}/>
                    <span className="text-xs font-medium uppercase tracking-wide">Qué necesitás para aplicar</span>
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {selected.requirements.map(r => (
                      <span key={r} className="bg-blue-50 text-blue-700 border border-blue-200 text-xs px-2.5 py-1 rounded-lg">{r}</span>
                    ))}
                  </div>
                </div>
              )}

              {/* Skills */}
              {selected.skills_needed?.length > 0 && (
                <div className="mb-6">
                  <div className="flex items-center gap-1.5 text-purple-600 mb-2">
                    <Code2 size={13}/>
                    <span className="text-xs font-medium uppercase tracking-wide">Skills que conviene tener</span>
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {selected.skills_needed.map(s => (
                      <span key={s} className="bg-purple-50 text-purple-700 border border-purple-200 text-xs px-2.5 py-1 rounded-lg font-mono">{s}</span>
                    ))}
                  </div>
                </div>
              )}

              {/* CTA */}
              <div className="flex gap-2 pt-4 border-t border-border">
                {selected.portal_url && (
                  <a href={selected.portal_url} target="_blank" rel="noopener noreferrer"
                    className="flex-1 flex items-center justify-center gap-2 bg-ink text-white hover:bg-ink/80 rounded-xl py-3 text-sm font-medium transition">
                    <ArrowUpRight size={14}/> Ir al portal de carreras
                  </a>
                )}
                {selected.linkedin_url && (
                  <a href={selected.linkedin_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center justify-center gap-2 bg-[#0A66C2] hover:bg-[#0A66C2]/90 text-white rounded-xl px-5 py-3 text-sm font-medium transition">
                    <Linkedin size={14}/> Seguir
                  </a>
                )}
              </div>

            </div>
          </div>
        </div>
      )}
    </div>
  )
}
