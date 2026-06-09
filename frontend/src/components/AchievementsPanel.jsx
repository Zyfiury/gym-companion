import { motion } from 'framer-motion'
import { TrophyIcon, SparklesIcon } from '@heroicons/react/24/outline'
import { getAchievementDetails, xpToNextLevel } from '../lib/gamification'

export default function AchievementsPanel({ userData }) {
  const g = userData.gamification || {}
  const xp = xpToNextLevel(g.xp || 0)
  const achievements = getAchievementDetails(g)

  return (
    <section className="card-glow" data-testid="achievements-panel">
      <div className="mb-4 flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-brand">
          <TrophyIcon className="h-5 w-5 text-white" />
        </div>
        <div className="flex-1">
          <h2 className="font-semibold">Achievements</h2>
          <p className="text-xs text-slate-400">Level {xp.level} · {g.xp ?? 0} XP · {g.streak ?? 0}-day streak</p>
        </div>
        <div className="flex items-center gap-1 rounded-full bg-violet-500/20 px-3 py-1 text-sm font-medium text-violet-300">
          <SparklesIcon className="h-4 w-4" />
          Lv.{xp.level}
        </div>
      </div>

      <div className="mb-4">
        <div className="mb-1 flex justify-between text-xs text-slate-400">
          <span>Progress to Level {xp.level + 1}</span>
          <span>{xp.current}/{xp.needed} XP</span>
        </div>
        <div className="h-2 overflow-hidden rounded-full bg-white/10">
          <motion.div
            className="h-full rounded-full bg-gradient-brand"
            animate={{ width: `${Math.min(xp.progress, 100)}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2">
        {achievements.map((a) => (
          <div
            key={a.id}
            className={`rounded-xl border p-3 text-sm transition ${
              a.earned ? 'border-violet-500/40 bg-violet-500/10' : 'border-white/5 bg-white/5 opacity-50'
            }`}
          >
            <span className="text-lg">{a.icon}</span>
            <p className="mt-1 font-medium">{a.name}</p>
            {a.earned && <p className="text-xs text-violet-400">Earned ✓</p>}
          </div>
        ))}
      </div>
    </section>
  )
}
