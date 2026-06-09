import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { SparklesIcon, EnvelopeIcon, LockClosedIcon, UserIcon } from '@heroicons/react/24/outline'
import { useAuth } from '../context/AuthContext'
import LoadingSpinner from './LoadingSpinner'

export default function Login() {
  const { login, signUp } = useAuth()
  const [tab, setTab] = useState('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      if (tab === 'login') {
        await login(email, password)
      } else {
        await signUp(email, password, displayName)
      }
    } catch (err) {
      setError(err.message || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-surface p-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md"
      >
        <div className="mb-8 text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200 }}
            className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-brand shadow-glow"
          >
            <SparklesIcon className="h-8 w-8 text-white" />
          </motion.div>
          <h1 className="bg-gradient-brand bg-clip-text text-3xl font-bold text-transparent">Gym Companion</h1>
          <p className="mt-2 text-sm text-slate-400">Your AI-powered fitness coach</p>
        </div>

        <div className="card-glow">
          <div className="mb-6 flex rounded-xl bg-white/5 p-1">
            {['login', 'signup'].map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => { setTab(t); setError('') }}
                className={`tap-haptic flex-1 rounded-lg py-2.5 text-sm font-medium capitalize transition-all ${
                  tab === t ? 'bg-gradient-brand text-white shadow-glow' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                {t === 'login' ? 'Login' : 'Sign Up'}
              </button>
            ))}
          </div>

          <AnimatePresence mode="wait">
            <motion.form
              key={tab}
              initial={{ opacity: 0, x: tab === 'login' ? -10 : 10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: tab === 'login' ? 10 : -10 }}
              onSubmit={handleSubmit}
              className="space-y-4"
            >
              {tab === 'signup' && (
                <div className="relative">
                  <UserIcon className="absolute left-3 top-3 h-5 w-5 text-slate-500" />
                  <input
                    type="text"
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    placeholder="Display name"
                    className="input-field pl-10"
                  />
                </div>
              )}
              <div className="relative">
                <EnvelopeIcon className="absolute left-3 top-3 h-5 w-5 text-slate-500" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email"
                  required
                  className="input-field pl-10"
                  data-testid="login-email"
                />
              </div>
              <div className="relative">
                <LockClosedIcon className="absolute left-3 top-3 h-5 w-5 text-slate-500" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Password (min 6 chars)"
                  required
                  minLength={6}
                  className="input-field pl-10"
                  data-testid="login-password"
                />
              </div>

              {error && (
                <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-red-400">
                  {error}
                </motion.p>
              )}

              <button type="submit" disabled={loading} className="btn-gradient tap-haptic w-full py-3" data-testid="login-submit">
                {loading ? <LoadingSpinner size="sm" /> : tab === 'login' ? 'Log in' : 'Create account'}
              </button>
            </motion.form>
          </AnimatePresence>
        </div>
      </motion.div>
    </div>
  )
}
