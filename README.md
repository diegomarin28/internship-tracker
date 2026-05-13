# 🎯 Internship Tracker — Setup completo

Stack: **Next.js + Supabase + Vercel + Resend**  
Todo gratis. Scanner diario con IA. Notificaciones por Gmail.

---

## Paso 1 — Clonar y abrir en VS Code

```bash
# En tu terminal
git clone https://github.com/diegomarin28/internship-tracker.git
cd internship-tracker
code .
npm install
```

---

## Paso 2 — Crear proyecto en Supabase

1. Ir a [supabase.com](https://supabase.com) → **New project**
2. Nombre: `internship-tracker`, elegí una región cercana (US East o EU West)
3. Esperá que termine de crear (~2 minutos)
4. Ir a **Settings → API** y copiar:
   - `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY`

---

## Paso 3 — Correr la migración SQL

1. En Supabase → **SQL Editor** → **New query**
2. Pegá todo el contenido de `supabase/migrations/001_init.sql`
3. Click **Run** — esto crea todas las tablas y carga los datos

---

## Paso 4 — Configurar Resend (emails gratis)

1. Ir a [resend.com](https://resend.com) → crear cuenta con tu Gmail
2. **API Keys** → **Create API Key** → copiar la key
3. Eso es todo, el tier gratis incluye 3.000 emails/mes

---

## Paso 5 — Obtener Anthropic API Key

1. Ir a [console.anthropic.com](https://console.anthropic.com)
2. **API Keys** → **Create Key**
3. Copiar la key (empieza con `sk-ant-...`)
4. El tier gratis o de pago funciona. Cada scan usa ~$0.01–0.05

---

## Paso 6 — Crear .env.local

En la raíz del proyecto, creá el archivo `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://TU_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=tu_anon_key
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key

RESEND_API_KEY=re_tu_key

NOTIFICATION_EMAIL=diegomarinarnoletti@gmail.com

ANTHROPIC_API_KEY=sk-ant-tu_key

CRON_SECRET=internship2027diego
```

---

## Paso 7 — Correr en local

```bash
npm run dev
```

Abrir [http://localhost:3000](http://localhost:3000)

Para testear el scanner manualmente, click en **"Scan ahora"** en el header.

---

## Paso 8 — Deploy en Vercel

```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel

# Seguir los pasos (conectar con GitHub account: diegomarin28)
# Cuando pregunte el proyecto: internship-tracker
```

Después del primer deploy:
1. Ir a [vercel.com](https://vercel.com) → tu proyecto → **Settings → Environment Variables**
2. Agregar **todas** las variables de `.env.local` una por una
3. Redeploy: `vercel --prod`

---

## Paso 9 — Usar el scanner

Una vez que la app esté corriendo, el botón **"🔍 Buscar vacantes"** en el header dispara el scanner manualmente.

Cada vez que lo clickeás:
- Analiza ~8 empresas de tu lista buscando posiciones abiertas
- Guarda lo que encuentra en Supabase (la tabla se actualiza en tiempo real)
- Te manda un mail con el resumen si encontró algo

Cuando en septiembre 2026 empiece a importar de verdad, podés activar el cron automático fácilmente — te explico en ese momento.

---

## Cómo funciona el scanner

Todos los días a las 8am UTC:
1. Elige 8 empresas al azar de tu lista
2. Busca en internet si tienen posiciones abiertas usando Claude AI
3. Si encuentra algo nuevo → lo guarda en Supabase → la tabla se actualiza en tiempo real en tu browser
4. Busca noticias del sector (robótica, IA, autos autónomos, telecomunicaciones)
5. Si encontró vacantes o hay deadlines próximos → te manda mail a diegomarinarnoletti@gmail.com con:
   - Las vacantes encontradas
   - Qué necesitás para aplicar (CV, cover letter, skills)
   - Fechas próximas de apertura

---

## Estructura del proyecto

```
internship-tracker/
├── app/
│   ├── components/
│   │   ├── CompanyTable.tsx   # Tabla principal con filtros
│   │   ├── OpeningsPanel.tsx  # Vacantes en tiempo real
│   │   ├── NewsPanel.tsx      # Noticias del sector
│   │   ├── StatsBar.tsx       # Estadísticas arriba
│   │   ├── Header.tsx         # Header + botón scan manual
│   │   └── DiffBadge.tsx      # Badge de dificultad
│   ├── api/cron/scan/
│   │   └── route.ts           # Scanner IA + emails
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx               # Página principal
├── lib/
│   └── supabase.ts            # Cliente Supabase + tipos
├── supabase/migrations/
│   └── 001_init.sql           # Schema + seed data (50+ empresas)
├── .env.local.example
├── vercel.json                # Cron config
└── README.md
```

---

## Agregar una empresa nueva

Simplemente corré este SQL en Supabase SQL Editor:

```sql
insert into companies (name, region, country, flag, area, portal_url, portal_label,
  apply_window, apply_month_start, apply_year_start,
  entry_difficulty, work_difficulty, note, linkedin_url, is_startup, city,
  salary_min_usd, salary_max_usd, salary_note, col_min_usd, col_max_usd, col_city,
  requirements, skills_needed)
values (
  'Nombre empresa', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software',
  'https://empresa.com/careers', 'empresa.com/careers',
  'Ene–Mar 2027', 1, 2027,
  'Media', 'Alta',
  'Descripción de la empresa y qué hacen.',
  'https://linkedin.com/company/empresa',
  false, 'Berlin',
  1200, 1800, '€1.200–1.800/mes',
  1500, 2200, 'Berlin',
  ARRAY['CV en inglés', 'Carta de motivación'],
  ARRAY['Python', 'Machine Learning']
);
```

La tabla se actualiza en tiempo real automáticamente.

---

## Costos

| Servicio | Plan | Costo |
|---|---|---|
| Supabase | Free tier | $0 |
| Vercel | Hobby | $0 |
| Resend | Free (3k emails/mes) | $0 |
| Anthropic API | ~$0.02/scan diario | ~$0.60/mes |
| **Total** | | **~$0.60/mes** |

El único costo real es la API de Claude para el scanner. Si querés evitar eso, podés deshabilitar el scanner automático y solo usar la tabla manualmente.
