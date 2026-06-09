/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['"DM Sans"', 'system-ui', 'sans-serif'],
      },
      colors: {
        surface: {
          DEFAULT: '#0a0a12',
          card: '#12121f',
          elevated: '#1a1a2e',
        },
        accent: {
          from: '#8b5cf6',
          to: '#3b82f6',
          purple: '#8b5cf6',
          blue: '#3b82f6',
        },
      },
      backgroundImage: {
        'gradient-brand': 'linear-gradient(135deg, #8b5cf6 0%, #6366f1 50%, #3b82f6 100%)',
        'gradient-card': 'linear-gradient(145deg, rgba(139,92,246,0.12) 0%, rgba(59,130,246,0.08) 100%)',
      },
      boxShadow: {
        glow: '0 0 24px rgba(139, 92, 246, 0.35)',
        card: '0 4px 24px rgba(0, 0, 0, 0.4)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        shimmer: 'shimmer 1.5s infinite',
      },
      keyframes: {
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
    },
  },
  plugins: [],
}
