import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const repoBase = '/gym-companion/'

export default defineConfig(({ mode }) => ({
  plugins: [react()],
  base: mode === 'production' ? repoBase : '/',
  server: {
    port: 5173,
    host: true,
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
}))
