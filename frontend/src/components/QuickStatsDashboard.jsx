import { motion } from 'framer-motion'
import { FireIcon, BoltIcon, BeakerIcon } from '@heroicons/react/24/solid'

const stats = [
  { key: 'calories', label: 'Calories', icon: FireIcon, color: 'from-orange-500 to-pink-500', unit: 'kcal', getValue: (d) => d.dailyMacrosLogged?.calories ?? 0, getTarget: (d) => d.weeklyPlan?.macros?.calories ?? d.tdee },
  { key: 'steps', label: 'Steps', icon: BoltIcon, color: 'from-violet-500 to-blue-500', unit: '', getValue: (d) => d.quickStats?.steps ?? 6420, getTarget: () => 10000 },
  { key: 'water', label: 'Water', icon: BeakerIcon, color: 'from-cyan-500 to-blue-500', unit: 'L', getValue: (d) => d.quickStats?.water ?? 1.8, getTarget: () => 2.5 },
]

export default function QuickStatsDashboard({ userData }) {
  return (
    <section className="space-y-3" data-testid="quick-stats">
      <h2 className="text-sm font-medium uppercase tracking-wider text-slate-500">Today</h2>
      <div className="grid grid-cols-3 gap-3">
        {stats.map((s, i) => {
          const Icon = s.icon
          const val = s.getValue(userData)
          const target = s.getTarget(userData)
          const pct = Math.min(100, Math.round((val / target) * 100))
          return (
            <motion.div
              key={s.key}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.08 }}
              className="card-glow tap-haptic relative overflow-hidden p-3"
            >
              <div className={`mb-2 inline-flex rounded-lg bg-gradient-to-br ${s.color} p-1.5`}>
                <Icon className="h-4 w-4 text-white" />
              </div>
              <p className="text-[10px] text-slate-400">{s.label}</p>
              <p className="text-lg font-bold">
                {typeof val === 'number' && val % 1 !== 0 ? val.toFixed(1) : val}
                {s.unit && <span className="text-xs font-normal text-slate-400"> {s.unit}</span>}
              </p>
              <div className="mt-2 h-1 overflow-hidden rounded-full bg-white/10">
                <motion.div
                  className={`h-full rounded-full bg-gradient-to-r ${s.color}`}
                  initial={{ width: 0 }}
                  animate={{ width: `${pct}%` }}
                  transition={{ duration: 0.8, ease: 'easeOut' }}
                />
              </div>
            </motion.div>
          )
        })}
      </div>
    </section>
  )
}
