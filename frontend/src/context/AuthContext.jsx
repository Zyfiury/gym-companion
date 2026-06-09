import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import {
  login as authLogin, signUp as authSignUp, saveSession, getSession, clearSession, ensureDemoTestAccount,
} from '../lib/auth'
import { setActiveUser, loadUserData, saveUserData, setupOfflineListeners, cacheWeeklyPlan } from '../lib/userStore'
import { getDefaultUserData } from '../lib/sessions'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(() => getSession())
  const [userData, setUserData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [online, setOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true)

  const loadUser = useCallback(async (userId) => {
    setActiveUser(userId)
    const data = await loadUserData(userId)
    setUserData(data)
    return data
  }, [])

  useEffect(() => {
    const init = async () => {
      await ensureDemoTestAccount()
      const s = getSession()
      if (s?.userId) {
        setActiveUser(s.userId)
        await loadUser(s.userId)
      }
      setLoading(false)
    }
    init()
  }, [loadUser])

  useEffect(() => {
    if (!session?.userId) return undefined
    return setupOfflineListeners(setOnline, session.userId)
  }, [session?.userId])

  const handleLogin = async (email, password) => {
    const account = await authLogin({ email, password })
    saveSession(account)
    setSession({ userId: account.userId, email: account.email, displayName: account.displayName })
    await loadUser(account.userId)
    return account
  }

  const handleSignUp = async (email, password, displayName) => {
    const account = await authSignUp({ email, password, displayName })
    saveSession(account)
    setSession({ userId: account.userId, email: account.email, displayName: account.displayName })
    const fresh = { ...getDefaultUserData(), userId: account.userId, profileComplete: false, displayName: account.displayName }
    await saveUserData(fresh, account.userId)
    setUserData(fresh)
    return account
  }

  const handleLogout = () => {
    clearSession()
    setSession(null)
    setUserData(null)
    setActiveUser(null)
  }

  const updateUserData = async (patch) => {
    if (!session?.userId || !userData) return
    const next = { ...userData, ...patch }
    if (patch.weeklyPlan) next.weeklyPlan = { ...userData.weeklyPlan, ...patch.weeklyPlan }
    setUserData(next)
    await saveUserData(next, session.userId)
    if (next.weeklyPlan) await cacheWeeklyPlan(next.weeklyPlan, session.userId)
  }

  const completeOnboarding = async (profile) => {
    if (!session?.userId) return
    const next = { ...userData, ...profile, profileComplete: true }
    setUserData(next)
    await saveUserData(next, session.userId)
  }

  return (
    <AuthContext.Provider value={{
      session,
      userData,
      loading,
      online,
      login: handleLogin,
      signUp: handleSignUp,
      logout: handleLogout,
      updateUserData,
      completeOnboarding,
      userId: session?.userId,
      displayName: session?.displayName,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
