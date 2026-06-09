import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  FireIcon, CakeIcon, UserIcon, ChartBarIcon, SunIcon, MoonIcon,
  ChatBubbleLeftRightIcon, NewspaperIcon, ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline'
import {
  FireIcon as FireSolid, CakeIcon as CakeSolid, UserIcon as UserSolid,
  ChartBarIcon as ChartSolid, ChatBubbleLeftRightIcon as ChatSolid, NewspaperIcon as NewspaperSolid,
} from '@heroicons/react/24/solid'
import UserProfileForm from './components/UserProfileForm'
import WorkoutPlanDisplay from './components/WorkoutPlanDisplay'
import MealPlanDisplay from './components/MealPlanDisplay'
import BarcodeScanner from './components/BarcodeScanner'
import ProgressTracking from './components/ProgressTracking'
import MealPrepMode from './components/MealPrepMode'
import BudgetTracker from './components/BudgetTracker'
import FavouriteMeals from './components/FavouriteMeals'
import ChatInterface from './components/ChatInterface'
import Feed from './components/Feed'
import AchievementsPanel from './components/AchievementsPanel'
import OfflineBanner from './components/OfflineBanner'
import Login from './components/Login'
import OnboardingWizard from './components/OnboardingWizard'
import LoadingSpinner from './components/LoadingSpinner'
import { useTheme } from './context/ThemeContext'
import { useAuth } from './context/AuthContext'

const TABS = [
  { id: 'chat', label: 'Chat', Icon: ChatBubbleLeftRightIcon, IconActive: ChatSolid },
  { id: 'profile', label: 'Profile', Icon: UserIcon, IconActive: UserSolid },
  { id: 'workout', label: 'Workout', Icon: FireIcon, IconActive: FireSolid },
  { id: 'meals', label: 'Meals', Icon: CakeIcon, IconActive: CakeSolid },
  { id: 'progress', label: 'Progress', Icon: ChartBarIcon, IconActive: ChartSolid },
  { id: 'feed', label: 'Feed', Icon: NewspaperIcon, IconActive: NewspaperSolid },
]

const pageVariants = {
  initial: { opacity: 0, x: 16 },
  animate: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: -16 },
}

export default function App() {
  const { session, userData, loading, online, logout, updateUserData, displayName } = useAuth()
  const [tab, setTab] = useState('chat')
  const { theme, toggleTheme } = useTheme()

  if (loading) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4">
        <LoadingSpinner size="lg" />
        <p className="text-sm text-slate-400">Loading…</p>
      </div>
    )
  }

  if (!session) return <Login />
  if (!userData?.profileComplete) return <OnboardingWizard />

  const goalLabel = userData.goal ? `${userData.goal} · ` : ''
  const cals = userData.weeklyPlan?.macros?.calories ?? userData.tdee

  return (
    <div className="relative mx-auto flex min-h-screen max-w-lg flex-col pb-24 md:max-w-2xl lg:max-w-4xl">
      <OfflineBanner online={online} />

      <header className="sticky top-0 z-20 border-b border-white/5 bg-surface/90 px-4 py-4 backdrop-blur-xl">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="bg-gradient-brand bg-clip-text text-xl font-bold text-transparent">Gym Companion</h1>
            <p className="text-sm text-slate-400">{displayName} · {goalLabel}{cals} kcal target</p>
          </div>
          <div className="flex items-center gap-1">
            <button type="button" onClick={logout} className="tap-haptic rounded-full border border-white/10 p-2.5 hover:bg-white/5" aria-label="Logout" data-testid="logout-btn">
              <ArrowRightOnRectangleIcon className="h-5 w-5 text-slate-400" />
            </button>
            <button type="button" onClick={toggleTheme} className="tap-haptic rounded-full border border-white/10 p-2.5 hover:bg-white/5" aria-label="Toggle theme">
              {theme === 'dark' ? <SunIcon className="h-5 w-5 text-amber-400" /> : <MoonIcon className="h-5 w-5 text-violet-600" />}
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 space-y-4 p-4">
        <AnimatePresence mode="wait">
          <motion.div key={tab} variants={pageVariants} initial="initial" animate="animate" exit="exit" transition={{ duration: 0.2 }}>
            {tab === 'chat' && <ChatInterface embedded userData={userData} onUpdate={updateUserData} onNavigate={setTab} />}
            {tab === 'profile' && (
              <>
                <AchievementsPanel userData={userData} />
                <UserProfileForm userData={userData} onUpdate={updateUserData} />
                <BudgetTracker userData={userData} onUpdate={updateUserData} />
                <FavouriteMeals userData={userData} onUpdate={updateUserData} />
              </>
            )}
            {tab === 'workout' && <WorkoutPlanDisplay userData={userData} onUpdate={updateUserData} />}
            {tab === 'meals' && (
              <>
                <MealPlanDisplay userData={userData} />
                <BarcodeScanner userData={userData} onUpdate={updateUserData} />
                <MealPrepMode userData={userData} />
              </>
            )}
            {tab === 'progress' && <ProgressTracking userData={userData} onUpdate={updateUserData} />}
            {tab === 'feed' && <Feed />}
          </motion.div>
        </AnimatePresence>
      </main>

      <nav className="fixed bottom-0 left-0 right-0 z-20 mx-auto max-w-lg border-t border-white/5 bg-surface-card/95 backdrop-blur-xl md:max-w-2xl lg:max-w-4xl">
        <div className="flex px-1">
          {TABS.map((t) => {
            const active = tab === t.id
            const Icon = active ? t.IconActive : t.Icon
            return (
              <button key={t.id} type="button" onClick={() => setTab(t.id)} className={`nav-tab tap-haptic ${active ? 'nav-tab-active' : ''}`} data-testid={`tab-${t.id}`}>
                <Icon className="h-6 w-6" />
                <span className="text-[10px]">{t.label}</span>
              </button>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
