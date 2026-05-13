import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'


// Simple web search via Claude AI
async function searchWithClaude(query: string): Promise<{ results: string; urls: string[] }> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': process.env.ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      tools: [{ type: 'web_search_20250305', name: 'web_search' }],
      messages: [{ role: 'user', content: query }],
    }),
  })
  const data = await response.json()
  const text = data.content?.filter((b: any) => b.type === 'text').map((b: any) => b.text).join('\n') || ''
  return { results: text, urls: [] }
}

// Parse AI response into structured openings/news
async function analyzeWithClaude(prompt: string): Promise<any> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': process.env.ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      messages: [{ role: 'user', content: prompt }],
    }),
  })
  const data = await response.json()
  const text = data.content?.[0]?.text || '{}'
  try {
    const clean = text.replace(/```json|```/g, '').trim()
    return JSON.parse(clean)
  } catch {
    return {}
  }
}

async function sendEmail(subject: string, html: string) {
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'Internship Tracker <notifications@resend.dev>',
      to: [process.env.NOTIFICATION_EMAIL!],
      subject,
      html,
    }),
  })
  return res.ok
}

function buildEmailHtml(openings: any[], news: any[], upcomingDeadlines: any[]): string {
  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><style>
  body { font-family: system-ui, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
  .card { background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; }
  h1 { color: #4338ca; margin: 0 0 4px; font-size: 22px; }
  h2 { color: #1a1a1e; font-size: 16px; margin: 0 0 12px; }
  .badge { display: inline-block; padding: 2px 10px; border-radius: 99px; font-size: 12px; font-weight: 600; }
  .green { background: #dcfce7; color: #15803d; }
  .yellow { background: #fef9c3; color: #854d0e; }
  .blue { background: #dbeafe; color: #1d4ed8; }
  .opening { border-left: 3px solid #4338ca; padding-left: 12px; margin-bottom: 12px; }
  .skill-tag { background: #ede9fe; color: #5b21b6; padding: 2px 8px; border-radius: 6px; font-size: 12px; display: inline-block; margin: 2px; }
  a { color: #4338ca; }
  .footer { text-align: center; color: #9ca3af; font-size: 12px; margin-top: 20px; }
</style></head>
<body>
  <div class="card">
    <h1>🎯 Internship Tracker</h1>
    <p style="color:#6b7280;margin:0">Resumen diario — ${new Date().toLocaleDateString('es-UY', { weekday: 'long', day: 'numeric', month: 'long' })}</p>
  </div>

  ${upcomingDeadlines.length > 0 ? `
  <div class="card">
    <h2>⚠️ Próximas fechas para aplicar</h2>
    ${upcomingDeadlines.map(d => `
      <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid #f3f4f6">
        <div>
          <strong>${d.flag} ${d.name}</strong>
          <span class="badge yellow" style="margin-left:8px">${d.apply_window}</span>
        </div>
        <a href="${d.portal_url}" style="font-size:13px">Aplicar →</a>
      </div>
    `).join('')}
  </div>
  ` : ''}

  ${openings.length > 0 ? `
  <div class="card">
    <h2>🟢 Nuevas vacantes detectadas (${openings.length})</h2>
    ${openings.map(o => `
      <div class="opening">
        <div style="font-weight:600;color:#1a1a1e">${o.title}</div>
        <div style="font-size:13px;color:#6b7280;margin:2px 0">${o.company_name} · ${o.location || ''}</div>
        ${o.description ? `<div style="font-size:13px;color:#374151;margin-top:4px">${o.description}</div>` : ''}
        <div style="margin-top:8px">
          ${(o.requirements || []).map((r: string) => `<span class="skill-tag">${r}</span>`).join('')}
        </div>
        ${o.url ? `<a href="${o.url}" style="font-size:13px;display:inline-block;margin-top:6px">Ver posición →</a>` : ''}
      </div>
    `).join('')}
  </div>
  ` : '<div class="card" style="text-align:center;color:#9ca3af">No se encontraron vacantes nuevas hoy.</div>'}

  ${news.length > 0 ? `
  <div class="card">
    <h2>📰 Noticias del sector (${news.length})</h2>
    ${news.slice(0, 5).map(n => `
      <div style="padding:8px 0;border-bottom:1px solid #f3f4f6">
        <div style="font-weight:600;font-size:14px">${n.title}</div>
        ${n.summary ? `<div style="font-size:13px;color:#6b7280;margin-top:2px">${n.summary}</div>` : ''}
        ${n.url ? `<a href="${n.url}" style="font-size:12px">Leer más →</a>` : ''}
      </div>
    `).join('')}
  </div>
  ` : ''}

  <div class="footer">
    Internship Tracker · diegomarin28 · Ingeniería Telemática 2027<br>
    <a href="${process.env.NEXT_PUBLIC_APP_URL || '#'}">Ver dashboard completo →</a>
  </div>
</body>
</html>`
}

export async function POST(req: NextRequest) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )
  const results = { scanned: 0, openings_found: 0, news_found: 0, email_sent: false }

  try {
    // Get all companies
    const { data: companies } = await supabase.from('companies').select('*')
    if (!companies) return NextResponse.json({ error: 'No companies' }, { status: 500 })

    const newOpenings: any[] = []
    const newNews: any[] = []

    // Scan a sample of companies per run (avoid rate limits)
    const toScan = companies.sort(() => Math.random() - 0.5).slice(0, 8)

    for (const company of toScan) {
      try {
        // Search for new internship openings
        const searchQuery = `"${company.name}" internship intern 2026 2027 software AI apply open position`
        const { results: searchResults } = await searchWithClaude(searchQuery)

        // Analyze results with AI
        const analysis = await analyzeWithClaude(`
You are analyzing web search results to find internship/job openings.
Company: ${company.name}
Search results: ${searchResults.slice(0, 2000)}

Return ONLY valid JSON (no markdown) in this exact format:
{
  "opening_found": true/false,
  "opening": {
    "title": "exact job title or null",
    "url": "direct application URL or null",
    "location": "city/remote or null",
    "deadline": "deadline date as string or null",
    "description": "2-3 sentence description of the role or null"
  },
  "news": {
    "found": true/false,
    "title": "news headline or null",
    "summary": "1-2 sentence summary or null",
    "url": "news URL or null",
    "relevance_score": 1-10
  }
}

Only return opening_found: true if there is a CURRENTLY OPEN application for an internship.`)

        if (analysis.opening_found && analysis.opening?.title) {
          // Check for duplicates
          const { data: existing } = await supabase
            .from('openings')
            .select('id')
            .eq('company_id', company.id)
            .eq('title', analysis.opening.title)
            .limit(1)

          if (!existing || existing.length === 0) {
            const { data: inserted } = await supabase.from('openings').insert({
              company_id: company.id,
              title: analysis.opening.title,
              url: analysis.opening.url,
              location: analysis.opening.location,
              deadline: analysis.opening.deadline,
              description: analysis.opening.description,
              is_active: true,
            }).select().single()

            if (inserted) {
              newOpenings.push({ ...inserted, company_name: company.name, flag: company.flag, requirements: company.requirements })
              results.openings_found++
            }
          }
        }

        if (analysis.news?.found && analysis.news?.title) {
          await supabase.from('news').insert({
            company_id: company.id,
            title: analysis.news.title,
            summary: analysis.news.summary,
            url: analysis.news.url,
            source: company.name,
            relevance_score: analysis.news.relevance_score || 5,
            category: analysis.opening_found ? 'internship_open' : 'company_news',
            published_at: new Date().toISOString(),
          })
          newNews.push({ ...analysis.news, company_name: company.name })
          results.news_found++
        }

        // Log scan
        await supabase.from('scan_log').insert({
          company_id: company.id,
          found_openings: analysis.opening_found ? 1 : 0,
          found_news: analysis.news?.found ? 1 : 0,
          status: 'ok',
        })

        results.scanned++
      } catch (err) {
        console.error(`Error scanning ${company.name}:`, err)
        await supabase.from('scan_log').insert({ company_id: company.id, status: 'error' })
      }
    }

    // Also search for general sector news
    const sectorSearch = await searchWithClaude(
      'AI robotics internship 2026 2027 startup Europe USA tech job opening telematics IoT automotive')
    if (sectorSearch.results) {
      const sectorNews = await analyzeWithClaude(`
Extract 2-3 relevant news items from these search results about AI/robotics/internships in tech.
Results: ${sectorSearch.results.slice(0, 2000)}
Return ONLY JSON array: [{"title": "...", "summary": "...", "url": "...", "relevance_score": 1-10}]
Only include genuinely interesting items for a telematics engineering student looking for internships.`)
      if (Array.isArray(sectorNews)) {
        for (const item of sectorNews.slice(0, 3)) {
          await supabase.from('news').insert({
            company_id: null,
            title: item.title,
            summary: item.summary,
            url: item.url,
            source: 'Sector scan',
            relevance_score: item.relevance_score || 5,
            category: 'sector_news',
            published_at: new Date().toISOString(),
          })
          newNews.push(item)
        }
      }
    }

    // Get upcoming deadlines (next 90 days)
    const now = new Date()
    const upcomingDeadlines = companies.filter(c => {
      if (c.apply_year_start < now.getFullYear()) return false
      if (c.apply_year_start === now.getFullYear() && c.apply_month_start <= now.getMonth() + 1) return false
      const monthsUntil = (c.apply_year_start - now.getFullYear()) * 12 + (c.apply_month_start - now.getMonth() - 1)
      return monthsUntil <= 3
    })

    // Send email if there's anything interesting
    const shouldEmail = newOpenings.length > 0 || upcomingDeadlines.length > 0 || newNews.length > 0
    if (shouldEmail && process.env.RESEND_API_KEY && process.env.NOTIFICATION_EMAIL) {
      const subject = newOpenings.length > 0
        ? `🟢 ${newOpenings.length} nueva(s) vacante(s) encontrada(s) — Internship Tracker`
        : upcomingDeadlines.length > 0
        ? `⚠️ Próximas fechas para aplicar — Internship Tracker`
        : `📰 Novedades del sector — Internship Tracker`

      const html = buildEmailHtml(newOpenings, newNews, upcomingDeadlines)
      results.email_sent = await sendEmail(subject, html)
    }

    return NextResponse.json({
      ...results,
      message: `Scan completado: ${results.scanned} empresas, ${results.openings_found} vacantes, ${results.news_found} noticias`,
    })
  } catch (err) {
    console.error('Scan error:', err)
    return NextResponse.json({ error: String(err) }, { status: 500 })
  }
}
