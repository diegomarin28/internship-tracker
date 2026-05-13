const STYLES: Record<string, string> = {
  'Baja':       'bg-green-50 text-green-700 border-green-200',
  'Baja-Media': 'bg-green-50 text-green-600 border-green-200',
  'Media':      'bg-blue-50 text-blue-700 border-blue-200',
  'Media-Alta': 'bg-amber-50 text-amber-700 border-amber-200',
  'Alta':       'bg-orange-50 text-orange-700 border-orange-200',
  'Muy Alta':   'bg-red-50 text-red-700 border-red-200',
}

export default function DiffBadge({ level }: { level: string }) {
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium border ${STYLES[level] || 'bg-subtle text-muted border-border'}`}>
      {level}
    </span>
  )
}
