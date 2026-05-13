/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'system-ui', 'sans-serif'],
        display: ['Syne', 'system-ui', 'sans-serif'],
      },
      colors: {
        bg: '#F5F4F0',
        card: '#FFFFFF',
        subtle: '#EEECEA',
        hover: '#E8E6E1',
        border: '#E0DDD8',
        'border-strong': '#C8C4BE',
        ink: '#141412',
        muted: '#6B6860',
        faint: '#A09D98',
      }
    },
  },
  plugins: [],
}
