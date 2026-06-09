import React from 'react'
import ReactDOM from 'react-dom/client'
import { ThemeProvider } from './context/ThemeContext'
import { AuthProvider } from './context/AuthContext'
import App from './App.jsx'
import './index.css'

// Google OAuth callback — token in URL hash
if (window.location.hash.includes('access_token')) {
  const token = new URLSearchParams(window.location.hash.slice(1)).get('access_token')
  if (token) {
    localStorage.setItem('gymapp_google_fit_token', JSON.stringify({ access_token: token, ts: Date.now() }))
    window.opener?.postMessage({ type: 'GOOGLE_FIT_TOKEN', token }, window.location.origin)
    window.close()
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <ThemeProvider>
      <AuthProvider>
        <App />
      </AuthProvider>
    </ThemeProvider>
  </React.StrictMode>,
)
