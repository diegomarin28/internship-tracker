-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_cron";

-- ============================================
-- COMPANIES TABLE
-- ============================================
create table if not exists companies (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  region text not null,          -- 'Europa' | 'EEUU' | 'Global'
  country text not null,
  flag text,
  area text not null,
  portal_url text,
  portal_label text,
  apply_window text,             -- human readable: "Ene–Mar 2027"
  apply_month_start int,         -- 1-12, for sorting/filtering
  apply_year_start int,
  entry_difficulty text,         -- 'Baja' | 'Media' | 'Media-Alta' | 'Alta' | 'Muy Alta'
  work_difficulty text,
  note text,
  linkedin_url text,
  is_startup boolean default false,
  city text,
  -- salary info
  salary_min_usd int,
  salary_max_usd int,
  salary_note text,
  -- cost of living (monthly USD estimate)
  col_min_usd int,
  col_max_usd int,
  col_city text,
  -- what you need to apply
  requirements text[],           -- ['CV en inglés', 'Cover Letter', 'Transcript']
  skills_needed text[],          -- ['Python', 'ML básico', 'C++']
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- OPENINGS TABLE - real-time job postings found
-- ============================================
create table if not exists openings (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references companies(id) on delete cascade,
  title text not null,
  url text,
  location text,
  deadline text,
  description text,
  is_notified boolean default false,  -- did we send email yet?
  is_active boolean default true,
  found_at timestamptz default now(),
  expires_at timestamptz
);

-- ============================================
-- NEWS TABLE - sector news & company updates
-- ============================================
create table if not exists news (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references companies(id) on delete set null,
  title text not null,
  summary text,
  url text,
  source text,
  relevance_score int default 0,  -- 1-10, AI-assigned
  category text,                  -- 'internship_open' | 'company_news' | 'sector_news'
  published_at timestamptz,
  created_at timestamptz default now()
);

-- ============================================
-- SCAN LOG - track when we last checked each company
-- ============================================
create table if not exists scan_log (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references companies(id) on delete cascade,
  scanned_at timestamptz default now(),
  found_openings int default 0,
  found_news int default 0,
  status text default 'ok'       -- 'ok' | 'error'
);

-- ============================================
-- ENABLE REALTIME on openings and news
-- ============================================
alter publication supabase_realtime add table openings;
alter publication supabase_realtime add table news;
alter publication supabase_realtime add table companies;

-- ============================================
-- INDEXES for performance
-- ============================================
create index if not exists idx_openings_company on openings(company_id);
create index if not exists idx_openings_active on openings(is_active) where is_active = true;
create index if not exists idx_openings_notified on openings(is_notified) where is_notified = false;
create index if not exists idx_news_company on news(company_id);
create index if not exists idx_news_created on news(created_at desc);
create index if not exists idx_companies_region on companies(region);
create index if not exists idx_companies_area on companies(area);
create index if not exists idx_companies_startup on companies(is_startup);

-- ============================================
-- UPDATED_AT trigger
-- ============================================
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger companies_updated_at
  before update on companies
  for each row execute function update_updated_at();

-- ============================================
-- SEED DATA - all companies
-- ============================================
insert into companies (name, region, country, flag, area, portal_url, portal_label, apply_window, apply_month_start, apply_year_start, entry_difficulty, work_difficulty, note, linkedin_url, is_startup, city, salary_min_usd, salary_max_usd, salary_note, col_min_usd, col_max_usd, col_city, requirements, skills_needed) values

-- GERMANY
('BMW Group', 'Europa', 'Alemania', '🇩🇪', 'Automotriz / IA', 'https://www.bmwgroup.jobs/en/students.html', 'bmwgroup.jobs', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'Werkstudent 6 meses. IA embebida, robótica, autos autónomos. 100% inglés en equipos tech. ~€1.200/mes.', 'https://www.linkedin.com/company/bmw-group/', false, 'Munich', 1200, 1500, '€1.200–1.500/mes', 1800, 2400, 'Munich', ARRAY['CV en inglés', 'Carta de motivación', 'Certificado de matrícula', 'Transcript'], ARRAY['Python', 'C++', 'Machine Learning básico', 'Sistemas embebidos']),

('Mercedes-Benz', 'Europa', 'Alemania', '🇩🇪', 'Automotriz / IA', 'https://group.mercedes-benz.com/careers/students/internship/', 'jobs.mercedes-benz.com', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'AI Engineering & Data Science. Inglés principal. Alojamiento disponible en Sindelfingen. ~€1.000/mes.', 'https://www.linkedin.com/company/mercedes-benz/', false, 'Stuttgart', 1000, 1400, '€1.000–1.400/mes', 1600, 2200, 'Stuttgart', ARRAY['CV en inglés', 'Carta de motivación', 'Certificado de matrícula', 'Transcript', 'Certificado de prácticas obligatorias'], ARRAY['Python', 'SQL', 'Data Science básico', 'TensorFlow o PyTorch básico']),

('Bosch', 'Europa', 'Alemania', '🇩🇪', 'Automotriz / IA', 'https://www.bosch.com/careers/', 'bosch.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'IoT, GenAI, IA embebida. €2.7B invertidos en IA. Munich o Stuttgart. ~€1.100/mes.', 'https://www.linkedin.com/company/bosch/', false, 'Munich / Stuttgart', 1100, 1400, '€1.100–1.400/mes', 1800, 2400, 'Munich', ARRAY['CV en inglés', 'Carta de motivación', 'Certificado de matrícula', 'Transcript'], ARRAY['Python', 'C++', 'IoT básico', 'Machine Learning']),

('Bosch AI Center', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://www.bosch-ai.com/careers/', 'bosch-ai.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media-Alta', 'Muy Alta', 'División IA pura de Bosch. Deep learning, robótica, computer vision aplicados a productos reales.', 'https://www.linkedin.com/company/bosch-center-for-artificial-intelligence/', false, 'Munich', 1200, 1500, '€1.200–1.500/mes', 1800, 2400, 'Munich', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript', 'Portfolio de proyectos AI'], ARRAY['Python', 'PyTorch', 'Deep Learning', 'Computer Vision', 'NLP básico']),

('Siemens', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://www.siemens.com/global/en/company/jobs.html', 'siemens.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'IA industrial, automatización, transporte. Siemens AI Lab en Munich y Berlín. ~€1.200/mes.', 'https://www.linkedin.com/company/siemens/', false, 'Munich / Berlín', 1200, 1500, '€1.200–1.500/mes', 1800, 2500, 'Berlín', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'Machine Learning', 'IoT', 'Sistemas de control básico']),

('KUKA', 'Europa', 'Alemania', '🇩🇪', 'Robótica / Automatización', 'https://www.kuka.com/en-de/company/careers/students', 'kuka.com/careers', 'Mar–May 2027', 3, 2027, 'Media', 'Alta', '~160 internships/año. Robótica industrial, Industria 4.0. Software de robots con IA. Augsburg o Bremen.', 'https://www.linkedin.com/company/kuka/', false, 'Augsburg', 900, 1200, '€900–1.200/mes', 1400, 1900, 'Augsburg', ARRAY['CV en inglés o alemán', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'C++', 'ROS básico', 'Sistemas embebidos']),

('SAP', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://jobs.sap.com/go/Students/3108700/', 'sap.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Media-Alta', 'Programa SAP iXp. IA en supply chain, logística, ERP. Inglés total. Walldorf, Berlín o Munich.', 'https://www.linkedin.com/company/sap/', false, 'Walldorf / Berlín', 1000, 1400, '€1.000–1.400/mes', 1500, 2500, 'Berlín', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'SQL', 'Cloud básico (AWS/Azure)', 'APIs REST']),

('Volkswagen', 'Europa', 'Alemania', '🇩🇪', 'Automotriz / IA', 'https://www.volkswagen-karriere.de/en/entry-opportunities/students/classic-internship.html', 'volkswagen-karriere.de', 'Ene–Mar 2027', 1, 2027, 'Media', 'Media-Alta', 'Software automotriz, digitalización, IA en producción. Wolfsburg, Berlín, Munich. ~€1.000/mes.', 'https://www.linkedin.com/company/volkswagen-ag/', false, 'Wolfsburg', 1000, 1300, '€1.000–1.300/mes', 1400, 1900, 'Wolfsburg', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'Embedded C', 'Machine Learning básico']),

('Continental', 'Europa', 'Alemania', '🇩🇪', 'Automotriz / IA', 'https://www.continental-jobs.com/', 'continental-jobs.com', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'ADAS, sensores, software automotriz. Sistemas de conducción asistida con IA. Hannover/Frankfurt.', 'https://www.linkedin.com/company/continental/', false, 'Hannover', 1000, 1300, '€1.000–1.300/mes', 1500, 2000, 'Hannover', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['C++', 'Python', 'Computer Vision básico', 'Sistemas embebidos']),

('Fraunhofer', 'Europa', 'Alemania', '🇩🇪', 'Investigación Aplicada', 'https://jobs.fraunhofer.de/', 'jobs.fraunhofer.de', 'Todo el año', 1, 2027, 'Media', 'Alta', '76 institutos. IPA (robótica), IAIS (ML), IIS (IoT). Aplica directamente al instituto que más te interese.', 'https://www.linkedin.com/company/fraunhofer-gesellschaft/', false, 'Munich / Berlín / Stuttgart', 800, 1200, '€800–1.200/mes', 1500, 2400, 'Munich', ARRAY['CV en inglés', 'Carta de motivación breve', 'Transcript'], ARRAY['Python', 'Machine Learning', 'ROS (para IPA)', 'C++ (para IIS)']),

-- NETHERLANDS
('TomTom', 'Europa', 'Países Bajos', '🇳🇱', 'Logística / IoT', 'https://www.tomtom.com/careers/', 'tomtom.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'Mapas inteligentes, navegación predictiva, IA para movilidad. Amsterdam. Inglés total. ~€1.400/mes.', 'https://www.linkedin.com/company/tomtom/', false, 'Amsterdam', 1400, 1800, '€1.400–1.800/mes', 1800, 2600, 'Amsterdam', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'Machine Learning', 'Algoritmos de grafos básico', 'APIs REST']),

('Booking.com', 'Europa', 'Países Bajos', '🇳🇱', 'IA Aplicada / Software', 'https://careers.booking.com/', 'careers.booking.com', 'Ene–Mar 2027', 1, 2027, 'Media-Alta', 'Alta', 'ML aplicado, optimización, recomendaciones con IA. Amsterdam. Muy accesible para internacionales.', 'https://www.linkedin.com/company/booking.com/', false, 'Amsterdam', 1400, 2000, '€1.400–2.000/mes', 1800, 2600, 'Amsterdam', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript', 'Portfolio de proyectos'], ARRAY['Python', 'SQL', 'Machine Learning', 'Estadística básica']),

('ASML', 'Europa', 'Países Bajos', '🇳🇱', 'IA Aplicada / Software', 'https://www.asml.com/en/careers/', 'asml.com/careers', 'Ene–Mar 2027', 1, 2027, 'Alta', 'Muy Alta', 'Software para chips. IA aplicada a manufactura de semiconductores. Eindhoven. ~€1.600/mes.', 'https://www.linkedin.com/company/asml/', false, 'Eindhoven', 1600, 2000, '€1.600–2.000/mes', 1600, 2200, 'Eindhoven', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript', 'Proyectos relevantes'], ARRAY['Python', 'C++', 'Machine Learning avanzado', 'Procesamiento de señales']),

('Philips', 'Europa', 'Países Bajos', '🇳🇱', 'IA Aplicada / Software', 'https://www.careers.philips.com/', 'careers.philips.com', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'IA aplicada a salud, IoT médico, análisis de datos. Amsterdam/Eindhoven. ~€1.200/mes.', 'https://www.linkedin.com/company/philips/', false, 'Amsterdam', 1200, 1600, '€1.200–1.600/mes', 1800, 2600, 'Amsterdam', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'Machine Learning', 'IoT básico', 'SQL']),

-- SWEDEN
('Ericsson', 'Europa', 'Suecia', '🇸🇪', 'Telecomunicaciones / Redes', 'https://www.ericsson.com/en/careers/student-young-professionals/internships', 'ericsson.com/careers', 'Dic 2026–Ene 2027', 12, 2026, 'Media-Alta', 'Alta', '5G, redes, ML en telecomunicaciones. Estocolmo. Ventana específica Dic–Ene. Alta competencia.', 'https://www.linkedin.com/company/ericsson/', false, 'Estocolmo', 1400, 1800, '€1.400–1.800/mes', 1600, 2200, 'Estocolmo', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'Redes (TCP/IP)', '5G básico', 'Machine Learning básico']),

-- FINLAND
('Nokia Bell Labs', 'Europa', 'Finlandia', '🇫🇮', 'Telecomunicaciones / Redes', 'https://www.nokia.com/careers/students-and-graduates/', 'nokia.com/careers', 'Ene–Mar 2027', 1, 2027, 'Alta', 'Muy Alta', 'Investigación en redes del futuro, IA, cloud networking. Espoo / múltiples sedes EU. Muy técnico.', 'https://www.linkedin.com/company/nokia/', false, 'Espoo', 1400, 1800, '€1.400–1.800/mes', 1500, 2100, 'Helsinki', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript', 'Papers o proyectos relevantes'], ARRAY['Python', 'C++', 'Redes avanzado', 'Machine Learning', 'Cloud (AWS/GCP)']),

-- FRANCE
('Thales', 'Europa', 'Francia', '🇫🇷', 'Aeroespacial / Defensa', 'https://careers.thalesgroup.com/global/en/studentandgraduates2', 'thalesgroup.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media-Alta', 'Alta', 'IA aplicada a defensa, aviación y transporte. Sede Italia (Gorgonzola) para navegación/radar.', 'https://www.linkedin.com/company/thales/', false, 'París / Gorgonzola IT', 1200, 1600, '€1.200–1.600/mes', 1800, 2600, 'París', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'C++', 'Machine Learning', 'Procesamiento de señales básico']),

('Airbus', 'Europa', 'Francia', '🇫🇷', 'Aeroespacial / Defensa', 'https://www.airbus.com/en/careers/students-and-graduates/interns', 'airbus.com/careers', 'Sep–Dic 2026', 9, 2026, 'Alta', 'Alta', 'Software, IA, robótica. Toulouse/Madrid/Alemania. OJO: aplica Sep–Dic 2026, más temprano que el resto.', 'https://www.linkedin.com/company/airbus/', false, 'Toulouse', 1200, 1600, '€1.200–1.600/mes', 1500, 2100, 'Toulouse', ARRAY['CV en inglés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'C++', 'Sistemas embebidos', 'Machine Learning básico']),

('Renault Software Labs', 'Europa', 'Francia', '🇫🇷', 'Automotriz / IA', 'https://www.renaultgroup.com/en/our-commitments/our-talents/', 'renaultgroup.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'IA automotriz, autos conectados, software embebido. París/Guyancourt. ~€1.000/mes.', 'https://www.linkedin.com/company/renault/', false, 'París', 1000, 1400, '€1.000–1.400/mes', 1800, 2800, 'París', ARRAY['CV en inglés o francés', 'Carta de motivación', 'Transcript'], ARRAY['Python', 'C++', 'Embedded systems', 'Machine Learning básico']),

('Capgemini', 'Europa', 'Francia', '🇫🇷', 'IA Aplicada / Software', 'https://www.capgemini.com/careers/', 'capgemini.com/careers', 'Todo el año', 1, 2027, 'Baja-Media', 'Media', 'Consultoría tech + IA. Proyectos variados en industria. Muy accesible. Offices en toda Europa.', 'https://www.linkedin.com/company/capgemini/', false, 'Múltiples', 800, 1200, '€800–1.200/mes', 1500, 2600, 'París', ARRAY['CV en inglés', 'Carta de motivación'], ARRAY['Python', 'SQL', 'Cloud básico', 'Comunicación técnica']),

-- SPAIN
('Indra', 'Europa', 'España', '🇪🇸', 'Aeroespacial / Defensa', 'https://www.indracompany.com/es/empleo', 'indracompany.com/empleo', 'Todo el año', 1, 2027, 'Baja', 'Media-Alta', 'Transporte inteligente, defensa, tecnología. Madrid. Sin trámites con pasaporte italiano.', 'https://www.linkedin.com/company/indra/', false, 'Madrid', 700, 1000, '€700–1.000/mes', 1200, 1800, 'Madrid', ARRAY['CV en español/inglés', 'Carta de motivación'], ARRAY['Python', 'Java básico', 'Redes básico', 'SQL']),

('Telefónica', 'Europa', 'España', '🇪🇸', 'Telecomunicaciones / Redes', 'https://www.telefonica.com/en/talent/', 'jobs.telefonica.com', 'Todo el año', 1, 2027, 'Baja', 'Media', 'Redes 5G, IoT, edge computing. Madrid/Barcelona. Sin trámites con pasaporte italiano.', 'https://www.linkedin.com/company/telefonica/', false, 'Madrid', 700, 1000, '€700–1.000/mes', 1200, 1800, 'Madrid', ARRAY['CV en español/inglés', 'Carta de motivación'], ARRAY['Redes (TCP/IP)', 'Python básico', '5G básico', 'IoT básico']),

-- IRELAND / UK
('Google EMEA', 'Europa', 'Irlanda', '🇮🇪', 'Big Tech', 'https://careers.google.com/students/', 'careers.google.com', 'Sep–Oct 2026', 9, 2026, 'Muy Alta', 'Muy Alta', 'SWE Intern. Londres, Zurich, Munich, Dublín. Algoritmos + sistema. Inglés total. ~€3.000–4.000/mes.', 'https://www.linkedin.com/company/google/', false, 'Dublín / Zurich / Munich', 3000, 4500, '€3.000–4.500/mes', 2000, 3000, 'Dublín', ARRAY['CV en inglés', 'Transcript', 'Portfolio GitHub'], ARRAY['Algoritmos y estructuras de datos avanzado', 'Python/Java/C++', 'LeetCode Medium/Hard', 'System Design básico']),

('Microsoft EMEA', 'Europa', 'Irlanda', '🇮🇪', 'Big Tech', 'https://careers.microsoft.com/students/', 'careers.microsoft.com', 'Jul–Oct 2026', 7, 2026, 'Alta', 'Alta', 'Azure AI, Copilot. Dublín / Londres. Sponsorean visa. Relocation incluida. ~€2.500–3.500/mes.', 'https://www.linkedin.com/company/microsoft/', false, 'Dublín', 2500, 3500, '€2.500–3.500/mes', 2000, 3000, 'Dublín', ARRAY['CV en inglés', 'Transcript'], ARRAY['Algoritmos y estructuras de datos', 'Python/Java/C#', 'LeetCode Medium', 'Cloud básico']),

-- USA - BIG TECH
('Google EEUU', 'EEUU', 'EEUU', '🇺🇸', 'Big Tech', 'https://careers.google.com/students/', 'careers.google.com', 'Jul–Oct 2026', 7, 2026, 'Muy Alta', 'Muy Alta', 'SWE / Robotics (Intrinsic). Mountain View/Seattle/NYC. J-1 visa. $40–43/hora + housing ~$15k/mes total.', 'https://www.linkedin.com/company/google/', false, 'Mountain View', 6000, 10000, '$6.000–10.000/mes', 3500, 5500, 'San Francisco Bay', ARRAY['CV en inglés', 'Transcript', 'Portfolio GitHub', 'Preparación LeetCode'], ARRAY['Algoritmos avanzado', 'Python/Java/C++', 'LeetCode Medium-Hard', 'System Design', 'ML básico']),

('Microsoft EEUU', 'EEUU', 'EEUU', '🇺🇸', 'Big Tech', 'https://careers.microsoft.com/students/', 'careers.microsoft.com', 'Jul–Oct 2026', 7, 2026, 'Alta', 'Alta', 'SWE Intern, Azure AI, Copilot. Redmond WA. Visa + relocation. $9.000–10.500/mes.', 'https://www.linkedin.com/company/microsoft/', false, 'Redmond WA', 9000, 10500, '$9.000–10.500/mes', 2500, 3500, 'Seattle', ARRAY['CV en inglés', 'Transcript', 'Portfolio GitHub'], ARRAY['Algoritmos y estructuras de datos', 'Python/Java/C#', 'LeetCode Medium', 'Cloud/Azure básico']),

('Meta', 'EEUU', 'EEUU', '🇺🇸', 'Big Tech', 'https://www.metacareers.com/students/', 'metacareers.com', 'Jul–Oct 2026', 7, 2026, 'Muy Alta', 'Muy Alta', 'IA, VR/AR, infraestructura. Menlo Park/NYC. J-1 visa. $51/hora + $2.600/mes housing.', 'https://www.linkedin.com/company/meta/', false, 'Menlo Park CA', 9000, 12000, '$9.000–12.000/mes', 3500, 5500, 'San Francisco Bay', ARRAY['CV en inglés', 'Transcript', 'Portfolio GitHub', 'Preparación LeetCode intensiva'], ARRAY['Algoritmos avanzado', 'Python/C++', 'LeetCode Hard', 'System Design avanzado', 'ML/AI']),

('Amazon', 'EEUU', 'EEUU', '🇺🇸', 'Big Tech', 'https://www.amazon.jobs/teams/internships-for-students', 'amazon.jobs', 'Jul–Oct 2026', 7, 2026, 'Alta', 'Alta', 'SDE Intern. Seattle/múltiples. J-1 visa. AWS, robótica, IA en logística. $8.000–10.000/mes.', 'https://www.linkedin.com/company/amazon/', false, 'Seattle WA', 8000, 10000, '$8.000–10.000/mes', 2500, 3500, 'Seattle', ARRAY['CV en inglés', 'Transcript', 'Preparación Leadership Principles', 'LeetCode'], ARRAY['Algoritmos y estructuras de datos', 'Python/Java', 'LeetCode Medium', 'Distributed systems básico']),

('NVIDIA', 'EEUU', 'EEUU', '🇺🇸', 'Semiconductores / Chips', 'https://www.nvidia.com/en-us/about-nvidia/careers/university-recruiting/', 'nvidia.com/careers', 'Oct 2026 (13 días)', 10, 2026, 'Muy Alta', 'Muy Alta', 'DRIVE (autos autónomos), robótica, IA embebida. Santa Clara. Ventana cortísima: solo 13 días en oct.', 'https://www.linkedin.com/company/nvidia/', false, 'Santa Clara CA', 8000, 11000, '$8.000–11.000/mes', 3500, 5000, 'Silicon Valley', ARRAY['CV en inglés', 'Transcript', 'Portfolio de proyectos GPU/AI', 'LeetCode'], ARRAY['C++', 'CUDA básico', 'Deep Learning', 'Python', 'Arquitecturas de hardware básico']),

('Qualcomm', 'EEUU', 'EEUU', '🇺🇸', 'Semiconductores / Chips', 'https://www.qualcomm.com/company/careers/internships-and-early-in-career-opportunities', 'qualcomm.com/careers', 'Sep–Ene 2026/27', 9, 2026, 'Alta', 'Muy Alta', '5G, IoT, IA para autos conectados, chips. San Diego. Visa. Muy técnico hardware+software.', 'https://www.linkedin.com/company/qualcomm/', false, 'San Diego CA', 7000, 10000, '$7.000–10.000/mes', 2500, 3500, 'San Diego', ARRAY['CV en inglés', 'Transcript', 'Proyectos de hardware/embedded', 'LeetCode'], ARRAY['C', 'C++', 'Sistemas embebidos avanzado', '5G/comunicaciones', 'DSP básico']),

('Tesla', 'EEUU', 'EEUU', '🇺🇸', 'Automotriz / IA', 'https://www.tesla.com/careers/search/', 'tesla.com/careers', 'Ago–Oct 2026', 8, 2026, 'Muy Alta', 'Muy Alta', 'Autopilot (visión + IA), embedded systems, robótica (Optimus). Palo Alto/Austin. J-1 visa.', 'https://www.linkedin.com/company/tesla-motors/', false, 'Palo Alto CA', 7000, 10000, '$7.000–10.000/mes', 3500, 5000, 'Silicon Valley', ARRAY['CV en inglés', 'Transcript', 'Portfolio de proyectos técnicos', 'GitHub activo'], ARRAY['Python', 'C++', 'Computer Vision', 'Deep Learning', 'Sistemas embebidos']),

('Waymo', 'EEUU', 'EEUU', '🇺🇸', 'Automotriz / IA', 'https://waymo.com/joinus/', 'waymo.com/careers', 'Ago–Nov 2026', 8, 2026, 'Muy Alta', 'Muy Alta', 'Vehículos autónomos, IA aplicada máxima. Mountain View. J-1 visa. Muy competitivo.', 'https://www.linkedin.com/company/waymo/', false, 'Mountain View CA', 8000, 12000, '$8.000–12.000/mes', 3500, 5500, 'San Francisco Bay', ARRAY['CV en inglés', 'Transcript', 'Portfolio fuerte en ML/robotics', 'Papers si tenés'], ARRAY['Python', 'C++', 'ROS', 'Deep Learning avanzado', 'Computer Vision avanzado']),

-- USA - TELECOM
('Nokia EEUU', 'EEUU', 'EEUU', '🇺🇸', 'Telecomunicaciones / Redes', 'https://www.nokia.com/about-us/careers/student-and-graduate-opportunities/us/', 'nokia.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', 'Redes, cloud, IA en telecomunicaciones. Co-op 4–18 meses. Naperville IL / múltiples.', 'https://www.linkedin.com/company/nokia/', false, 'Naperville IL', 4000, 6000, '$4.000–6.000/mes', 1800, 2500, 'Chicago', ARRAY['CV en inglés', 'Transcript'], ARRAY['Python', 'Redes (TCP/IP)', 'Cloud básico', 'C++ básico']),

('Ericsson EEUU', 'EEUU', 'EEUU', '🇺🇸', 'Telecomunicaciones / Redes', 'https://www.ericsson.com/en/careers/student-young-professionals/internships-us-canada', 'ericsson.com/careers', 'Ene–Mar 2027', 1, 2027, 'Media', 'Alta', '5G, redes, IA aplicada a telecomunicaciones. EEUU y Canadá. J-1 visa.', 'https://www.linkedin.com/company/ericsson/', false, 'Múltiples', 4000, 6000, '$4.000–6.000/mes', 2000, 3000, 'Nueva York', ARRAY['CV en inglés', 'Transcript'], ARRAY['Python', 'Redes avanzado', '5G', 'Machine Learning básico']),

-- GLOBAL
('IBM', 'Global', 'Global', '🌐', 'IA Aplicada / Software', 'https://www.ibm.com/careers/entry-level', 'ibm.com/careers', 'Todo el año', 1, 2027, 'Media', 'Media-Alta', 'Watson AI, cloud, consultoría tech. Múltiples países EU y EEUU. Muy accesible para internacionales.', 'https://www.linkedin.com/company/ibm/', false, 'Múltiples', 2000, 5000, 'Varía por país', 1500, 3500, 'Varía', ARRAY['CV en inglés', 'Carta de motivación'], ARRAY['Python', 'SQL', 'Cloud (IBM/AWS)', 'Machine Learning básico']),

('Accenture', 'Global', 'Global', '🌐', 'IA Aplicada / Software', 'https://www.accenture.com/us-en/careers/local/student-intern', 'accenture.com/careers', 'Todo el año', 1, 2027, 'Baja', 'Media', 'IA aplicada en consultoría. Proyectos variados. Muy accesible. Presente en Uruguay también.', 'https://www.linkedin.com/company/accenture/', false, 'Múltiples', 1500, 4000, 'Varía por país', 1200, 3500, 'Varía', ARRAY['CV en inglés', 'Carta de motivación'], ARRAY['Python básico', 'SQL', 'Comunicación técnica']),

('Deloitte Tech', 'Global', 'Global', '🌐', 'IA Aplicada / Software', 'https://www2.deloitte.com/global/en/careers/students.html', 'deloitte.com/careers', 'Todo el año', 1, 2027, 'Baja-Media', 'Media', 'IA, data, ciberseguridad en consultoría. Global. Buena puerta de entrada al mercado tech.', 'https://www.linkedin.com/company/deloitte/', false, 'Múltiples', 1500, 4000, 'Varía por país', 1200, 3500, 'Varía', ARRAY['CV en inglés', 'Carta de motivación'], ARRAY['Python básico', 'SQL', 'Cloud básico', 'Comunicación técnica']),

-- STARTUPS EUROPA
('Helsing', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://helsing.ai/careers', 'helsing.ai/careers', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'Startup de IA de defensa. Munich/Londres. Muy técnico, equipos pequeños, impacto enorme. Bien pago.', 'https://www.linkedin.com/company/helsing-ai/', true, 'Munich', 2000, 3000, '€2.000–3.000/mes', 1800, 2500, 'Munich', ARRAY['CV en inglés', 'Portfolio técnico fuerte', 'GitHub activo'], ARRAY['Python', 'C++', 'ML avanzado', 'Systems programming']),

('Celonis', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://www.celonis.com/careers/', 'celonis.com/careers', 'Todo el año', 1, 2027, 'Media-Alta', 'Alta', 'Process mining con IA. Munich. Unicornio europeo. Ideal para IA en logística y operaciones.', 'https://www.linkedin.com/company/celonis/', true, 'Munich', 1500, 2200, '€1.500–2.200/mes', 1800, 2500, 'Munich', ARRAY['CV en inglés', 'Carta de motivación', 'Portfolio'], ARRAY['Python', 'SQL', 'Machine Learning', 'APIs REST']),

('Personio', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://www.personio.com/about-personio/careers/', 'personio.com/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'HR tech con IA. Munich. Unicornio. Buen ambiente para aprender full-stack + IA aplicada.', 'https://www.linkedin.com/company/personio/', true, 'Munich', 1400, 2000, '€1.400–2.000/mes', 1800, 2500, 'Munich', ARRAY['CV en inglés', 'Carta de motivación', 'Portfolio'], ARRAY['Python', 'TypeScript/React', 'SQL', 'APIs']),

('Merantix', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://merantix.com/careers/', 'merantix.com/careers', 'Todo el año', 1, 2027, 'Media-Alta', 'Alta', 'Venture studio de IA. Berlín. Crean startups de IA con impacto real en industria. Muy interesante.', 'https://www.linkedin.com/company/merantix/', true, 'Berlín', 1200, 1800, '€1.200–1.800/mes', 1500, 2200, 'Berlín', ARRAY['CV en inglés', 'Portfolio de proyectos IA', 'GitHub activo'], ARRAY['Python', 'PyTorch/TensorFlow', 'ML aplicado', 'Datos reales']),

('Taxfix', 'Europa', 'Alemania', '🇩🇪', 'IA Aplicada / Software', 'https://taxfix.de/en/careers/', 'taxfix.de/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'Fintech con IA. Berlín. Buen ambiente de startup, inglés total, aprenderías MLOps y producto real.', 'https://www.linkedin.com/company/taxfix/', true, 'Berlín', 1200, 1800, '€1.200–1.800/mes', 1500, 2200, 'Berlín', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'Machine Learning', 'SQL', 'Cloud básico']),

('Mistral AI', 'Europa', 'Francia', '🇫🇷', 'IA Aplicada / Software', 'https://mistral.ai/company/careers/', 'mistral.ai/careers', 'Todo el año', 1, 2027, 'Muy Alta', 'Muy Alta', 'Startup de LLMs europea. París. La rival europea de OpenAI. Si entrás acá, el CV es espectacular.', 'https://www.linkedin.com/company/mistral-ai/', true, 'París', 2000, 3500, '€2.000–3.500/mes', 1800, 2800, 'París', ARRAY['CV en inglés', 'Portfolio técnico muy fuerte', 'Papers publicados idealmente', 'GitHub activo'], ARRAY['Python avanzado', 'PyTorch avanzado', 'LLMs', 'ML Research', 'C++ básico']),

('Pigment', 'Europa', 'Francia', '🇫🇷', 'IA Aplicada / Software', 'https://www.gopigment.com/careers/', 'gopigment.com/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'Business planning con IA. París. Unicornio en crecimiento. Buen stack técnico moderno.', 'https://www.linkedin.com/company/pigment-hq/', true, 'París', 1500, 2200, '€1.500–2.200/mes', 1800, 2800, 'París', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'TypeScript', 'SQL', 'APIs REST']),

('Wayve', 'Europa', 'Reino Unido', '🇬🇧', 'Automotriz / IA', 'https://wayve.ai/careers/', 'wayve.ai/careers', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'Startup de vehículos autónomos con IA. Londres. Respaldada por NVIDIA y Microsoft. Muy técnico.', 'https://www.linkedin.com/company/wayve/', true, 'Londres', 2000, 3000, '£2.000–3.000/mes', 2200, 3500, 'Londres', ARRAY['CV en inglés', 'Portfolio técnico fuerte', 'GitHub', 'Proyectos en CV/robotics'], ARRAY['Python', 'C++', 'Deep Learning', 'Computer Vision', 'ROS']),

('Tractable', 'Europa', 'Reino Unido', '🇬🇧', 'IA Aplicada / Software', 'https://tractable.ai/careers/', 'tractable.ai/careers', 'Todo el año', 1, 2027, 'Media-Alta', 'Alta', 'IA para seguros y recuperación de desastres. Londres. Computer vision aplicada a casos reales.', 'https://www.linkedin.com/company/tractable/', true, 'Londres', 1800, 2800, '£1.800–2.800/mes', 2200, 3500, 'Londres', ARRAY['CV en inglés', 'Portfolio técnico', 'GitHub'], ARRAY['Python', 'Computer Vision', 'Deep Learning', 'PyTorch']),

('Onfido', 'Europa', 'Reino Unido', '🇬🇧', 'IA Aplicada / Software', 'https://onfido.com/careers/', 'onfido.com/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'Verificación de identidad con IA. Londres. Computer vision + NLP aplicados a seguridad digital.', 'https://www.linkedin.com/company/onfido/', true, 'Londres', 1800, 2600, '£1.800–2.600/mes', 2200, 3500, 'Londres', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'Computer Vision básico', 'ML aplicado', 'SQL']),

('Hugging Face', 'Europa', 'Francia', '🇫🇷', 'IA Aplicada / Software', 'https://apply.workable.com/huggingface/', 'apply.workable.com/huggingface', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'La plataforma de ML open source más importante del mundo. París/remoto. Para el CV, es oro.', 'https://www.linkedin.com/company/huggingface/', true, 'París / Remoto', 1800, 3000, '€1.800–3.000/mes', 1800, 2800, 'París', ARRAY['CV en inglés', 'Contribuciones open source idealmente', 'GitHub activo fuerte', 'Papers si tenés'], ARRAY['Python avanzado', 'PyTorch', 'Transformers', 'NLP/LLMs', 'Open source contribution']),

('Greyparrot', 'Europa', 'Reino Unido', '🇬🇧', 'IA Aplicada / Software', 'https://www.greyparrot.ai/careers', 'greyparrot.ai/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'IA para reciclaje y sostenibilidad. Londres. Computer vision para resolver un problema real del mundo.', 'https://www.linkedin.com/company/greyparrot-ai/', true, 'Londres', 1500, 2500, '£1.500–2.500/mes', 2200, 3500, 'Londres', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'Computer Vision', 'PyTorch', 'IoT básico']),

-- STARTUPS EEUU
('OpenAI', 'EEUU', 'EEUU', '🇺🇸', 'IA Aplicada / Software', 'https://openai.com/careers/', 'openai.com/careers', 'Todo el año', 1, 2027, 'Muy Alta', 'Muy Alta', 'La empresa de IA más importante del mundo. SF. Para el CV es el máximo. Muy pocas plazas.', 'https://www.linkedin.com/company/openai/', true, 'San Francisco CA', 8000, 14000, '$8.000–14.000/mes', 3500, 5500, 'San Francisco', ARRAY['CV en inglés excepcional', 'Portfolio técnico muy fuerte', 'Papers o proyectos relevantes', 'GitHub activo'], ARRAY['Python avanzado', 'PyTorch avanzado', 'LLMs', 'ML Research', 'Sistemas distribuidos']),

('Anduril', 'EEUU', 'EEUU', '🇺🇸', 'IA Aplicada / Software', 'https://www.anduril.com/careers/', 'anduril.com/careers', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'Defensa + IA. Costa Mesa CA. Drones autónomos, robótica, sistemas embebidos. Muy bien pagado.', 'https://www.linkedin.com/company/anduril-industries/', true, 'Costa Mesa CA', 7000, 11000, '$7.000–11.000/mes', 2500, 3500, 'Los Angeles', ARRAY['CV en inglés', 'Portfolio técnico', 'GitHub activo'], ARRAY['C++', 'Python', 'ROS', 'Sistemas embebidos', 'Control systems']),

('Cruise', 'EEUU', 'EEUU', '🇺🇸', 'Automotriz / IA', 'https://getcruise.com/careers/', 'getcruise.com/careers', 'Ago–Nov 2026', 8, 2026, 'Alta', 'Muy Alta', 'Vehículos autónomos (GM). San Francisco. Muy técnico, IA + robótica en producción real.', 'https://www.linkedin.com/company/cruise-automation/', true, 'San Francisco CA', 7000, 11000, '$7.000–11.000/mes', 3500, 5500, 'San Francisco', ARRAY['CV en inglés', 'Portfolio en ML/robotics', 'GitHub activo'], ARRAY['Python', 'C++', 'Deep Learning', 'Computer Vision', 'ROS']),

('Cohere', 'EEUU', 'EEUU', '🇺🇸', 'IA Aplicada / Software', 'https://cohere.com/careers', 'cohere.com/careers', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'Startup de LLMs enterprise. San Francisco/Toronto. Rival de OpenAI en el espacio empresarial.', 'https://www.linkedin.com/company/cohere-ai/', true, 'San Francisco CA', 7000, 11000, '$7.000–11.000/mes', 3500, 5500, 'San Francisco', ARRAY['CV en inglés', 'Portfolio técnico fuerte', 'GitHub activo'], ARRAY['Python avanzado', 'NLP/LLMs', 'PyTorch', 'ML Research']),

('Scale AI', 'EEUU', 'EEUU', '🇺🇸', 'IA Aplicada / Software', 'https://scale.com/careers', 'scale.com/careers', 'Todo el año', 1, 2027, 'Alta', 'Alta', 'Datos para IA. San Francisco. Trabajan con el Pentágono, Tesla, OpenAI. Clave en la cadena de IA.', 'https://www.linkedin.com/company/scaleai/', true, 'San Francisco CA', 7000, 10000, '$7.000–10.000/mes', 3500, 5500, 'San Francisco', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'ML pipelines', 'SQL', 'Distributed systems básico']),

('Nuro', 'EEUU', 'EEUU', '🇺🇸', 'Automotriz / IA', 'https://www.nuro.ai/careers', 'nuro.ai/careers', 'Todo el año', 1, 2027, 'Alta', 'Muy Alta', 'Robots de entrega autónomos. Mountain View. IA + robótica en logística de última milla. Muy técnico.', 'https://www.linkedin.com/company/nuro/', true, 'Mountain View CA', 7000, 11000, '$7.000–11.000/mes', 3500, 5500, 'Silicon Valley', ARRAY['CV en inglés', 'Portfolio técnico', 'GitHub activo'], ARRAY['Python', 'C++', 'ROS', 'Computer Vision', 'Control systems']),

('Imbue', 'EEUU', 'EEUU', '🇺🇸', 'IA Aplicada / Software', 'https://imbue.com/careers/', 'imbue.com/careers', 'Todo el año', 1, 2027, 'Muy Alta', 'Muy Alta', 'Investigación en agentes IA con razonamiento. SF. Pequeño equipo, enorme impacto. Para perfiles muy fuertes.', 'https://www.linkedin.com/company/imbue-ai/', true, 'San Francisco CA', 8000, 14000, '$8.000–14.000/mes', 3500, 5500, 'San Francisco', ARRAY['CV en inglés excepcional', 'Portfolio de investigación', 'Papers publicados idealmente'], ARRAY['Python avanzado', 'PyTorch avanzado', 'RL/Agentes', 'ML Research avanzado']),

('Locus Robotics', 'EEUU', 'EEUU', '🇺🇸', 'Robótica / Automatización', 'https://locusrobotics.com/careers/', 'locusrobotics.com/careers', 'Todo el año', 1, 2027, 'Media-Alta', 'Alta', 'Robótica autónoma para almacenes/logística. Boston MA. IA + robótica resolviendo supply chain real.', 'https://www.linkedin.com/company/locus-robotics/', true, 'Wilmington MA', 5000, 8000, '$5.000–8.000/mes', 2000, 3000, 'Boston', ARRAY['CV en inglés', 'Portfolio técnico', 'GitHub'], ARRAY['Python', 'ROS', 'C++', 'Machine Learning básico', 'IoT']),

('Symbotic', 'EEUU', 'EEUU', '🇺🇸', 'Robótica / Automatización', 'https://www.symbotic.com/careers/', 'symbotic.com/careers', 'Todo el año', 1, 2027, 'Media', 'Alta', 'Robótica + IA en supply chain/almacenes. Wilmington MA. Trabajan con Walmart. Muy concreto.', 'https://www.linkedin.com/company/symbotic/', true, 'Wilmington MA', 5000, 8000, '$5.000–8.000/mes', 2000, 3000, 'Boston', ARRAY['CV en inglés', 'Portfolio', 'GitHub'], ARRAY['Python', 'C++', 'ROS básico', 'Algoritmos', 'Embedded básico']);
