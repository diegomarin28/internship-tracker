import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export const supabaseAdmin = () =>
  createClient(supabaseUrl, process.env.SUPABASE_SERVICE_ROLE_KEY!)

export type Company = {
  id: string
  name: string
  region: string
  country: string
  flag: string
  area: string
  portal_url: string
  portal_label: string
  apply_window: string
  apply_month_start: number
  apply_year_start: number
  entry_difficulty: string
  work_difficulty: string
  note: string
  linkedin_url: string
  is_startup: boolean
  city: string
  salary_min_usd: number
  salary_max_usd: number
  salary_note: string
  col_min_usd: number
  col_max_usd: number
  col_city: string
  requirements: string[]
  skills_needed: string[]
}

export type Opening = {
  id: string
  company_id: string
  title: string
  url: string
  location: string
  deadline: string
  description: string
  is_notified: boolean
  is_active: boolean
  found_at: string
  companies?: Company
}

export type NewsItem = {
  id: string
  company_id: string | null
  title: string
  summary: string
  url: string
  source: string
  relevance_score: number
  category: string
  published_at: string
  created_at: string
  companies?: Company
}
