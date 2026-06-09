import { useState } from 'react'
import { motion } from 'framer-motion'
import { ChartBarIcon, TrophyIcon, LightBulbIcon } from '@heroicons/react/24/outline'
import HealthMetrics from './HealthMetrics'
import { formatHealthInsight } from '../lib/healthData'
import { generateLocalInsights } from '../lib/insights'
import { awardXP } from '../lib/gamification'

function detectPlateau(history, goal) {
  if (history.length < 3) return null
  const recent = history.slice(-3).map((h) => h.weight)
  const spread = Math.max(...recent) - Math.min(...recent)
  if (spread < 0.3 && goal === 'cut') return 'Weight plateau detected. Consider a small deficit tweak or deload week.'
  if (spread < 0.3 && goal === 'bulk') return 'Gain plateau — add 100–150 kcal or an extra compound set.'
  return null
}

export default function ProgressTracking({ userData, onUpdate }) {
  const [weight, setWeight] = useState('')
  const [pr, setPr] = useState({ lift: '', value: '' })
  const history = userData.weightHistory ?? []
  const plateau = detectPlateau(history, userData.goal)
  const maxW = Math.max(...history.map((h) => h.weight), 1)
  const minW = Math.min(...history.map((h) => h.weight), maxW - 5)
  const healthInsights = formatHealthInsight(userData.healthMetrics || {})
  const localInsights = generateLocalInsights(userData).slice(0, 2)

  const logPR = () => {
    if (!pr.lift || !pr.value) return
    const personalRecords = [...(userData.personalRecords ?? []), { ...pr, date: new Date().toISOString().slice(0, 10) }]
    const gamification = awardXP({ ...userData, personalRecords }, 'workout')
    onUpdate({ personalRecords, gamification })
    setPr({ lift: '', value: '' })
  }

  return (
    <section className="space-y-4" data-testid="progress-tracking">
      <HealthMetrics userData={userData} onUpdate={onUpdate} />

      {plateau && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="card flex gap-3 border-amber-500/30 bg-amber-500/10" data-testid="plateau-alert">
          <LightBulbIcon className="h-6 w-6 shrink-0 text-amber-400" />
          <p className="text-sm text-amber-200">{plateau}</p>
        </motion.div>
      )}

      {localInsights.map((ins, i) => (
        <div key={i} className="card flex gap-3 border-violet-500/20 bg-violet-500/5">
          <LightBulbIcon className="h-5 w-5 shrink-0 text-violet-400" />
          <p className="text-sm text-slate-300">{ins}</p>
        </div>
      ))}

      {healthInsights.map((ins, i) => (
        <div key={`h-${i}`} className="card flex gap-3 border-blue-500/20 bg-blue-500/5">
          <LightBulbIcon className="h-5 w-5 shrink-0 text-blue-400" />
          <p className="text-sm text-slate-300">{ins}</p>
        </div>
      ))}

      <div className="card-glow">
        <div className="mb-3 flex items-center gap-2">
          <ChartBarIcon className="h-5 w-5 text-violet-400" />
          <h2 className="font-semibold">Weight trend</h2>
        </div>
        <div className="flex h-36 items-end gap-1.5" data-testid="weight-chart">
          {history.map((h, i) => {
            const pct = ((h.weight - minW) / (maxW - minW || 1)) * 100
            return (
              <div key={i} className="flex flex-1 flex-col items-center justify-end gap-1">
                <motion.div
                  className="w-full rounded-t-lg bg-gradient-brand"
                  initial={{ height: 0 }}
                  animate={{ height: `${Math.max(pct, 10)}%` }}
                  transition={{ delay: i * 0.05, duration: 0.4 }}
                />
                <span className="text-[10px] text-slate-500">{h.date.slice(5)}</span>
              </div>
            )
          })}
        </div>
        <div className="mt-4 flex gap-2">
          <input type="number" step="0.1" value={weight} onChange={(e) => setWeight(e.target.value)} placeholder="kg" className="input-field" data-testid="weight-input" />
          <button type="button" onClick={() => { if (weight) { onUpdate({ weightHistory: [...history, { date: new Date().toISOString().slice(0, 10), weight: Number(weight) }] }); setWeight('') } }} className="btn-gradient tap-haptic" data-testid="log-weight">Log</button>
        </div>
      </div>

      <div className="card">
        <div className="mb-3 flex items-center gap-2">
          <TrophyIcon className="h-5 w-5 text-violet-400" />
          <h3 className="font-semibold">Personal records</h3>
        </div>
        <div className="mb-2 flex gap-2">
          <input type="text" value={pr.lift} onChange={(e) => setPr((p) => ({ ...p, lift: e.target.value }))} placeholder="Lift" className="input-field" />
          <input type="text" value={pr.value} onChange={(e) => setPr((p) => ({ ...p, value: e.target.value }))} placeholder="100kg × 5" className="input-field" />
          <button type="button" onClick={logPR} className="btn-gradient tap-haptic shrink-0 px-3">+</button>
        </div>
        <ul className="space-y-1 text-sm text-slate-300">
          {(userData.personalRecords ?? []).slice(-5).map((r, i) => (
            <li key={i}>{r.lift}: {r.value} <span className="text-slate-500">({r.date})</span></li>
          ))}
        </ul>
      </div>
    </section>
  )
}
