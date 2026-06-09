import { useState } from 'react'
import { HeartIcon, MoonIcon, FireIcon, SignalIcon } from '@heroicons/react/24/outline'
import { connectGoogleFit, connectHealthKit } from '../lib/healthData'
import { useAuth } from '../context/AuthContext'
import HealthCharts from './HealthCharts'
import LoadingSpinner from './LoadingSpinner'

export default function HealthMetrics({ userData, onUpdate }) {
  const { userId } = useAuth()
  const [connecting, setConnecting] = useState(false)
  const metrics = userData.healthMetrics || {}

  const handleConnect = async () => {
    setConnecting(true)
    const result = await connectGoogleFit(userId)
    onUpdate({ healthMetrics: { ...metrics, ...result } })
    setConnecting(false)
  }

  const stats = [
    { icon: SignalIcon, label: 'Steps', value: metrics.steps?.toLocaleString() ?? '—', color: 'text-blue-400' },
    { icon: HeartIcon, label: 'Heart rate', value: metrics.heartRate ? `${metrics.heartRate} bpm` : '—', color: 'text-red-400' },
    { icon: MoonIcon, label: 'Sleep', value: metrics.sleepHours ? `${metrics.sleepHours}h` : '—', color: 'text-indigo-400' },
    { icon: FireIcon, label: 'Calories burned', value: metrics.caloriesBurned ?? '—', color: 'text-orange-400' },
  ]

  return (
    <section className="space-y-4" data-testid="health-metrics">
      <div className="card">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="font-semibold">Health metrics</h3>
          <span className="rounded-full bg-white/10 px-2 py-0.5 text-xs text-slate-400">
            {metrics.source === 'google_fit' ? 'Google Fit' : metrics.source === 'mock' ? 'Demo data' : metrics.source || 'Not connected'}
          </span>
        </div>
        <div className="mb-3 grid grid-cols-2 gap-2">
          {stats.map((s) => (
            <div key={s.label} className="rounded-xl bg-white/5 p-3">
              <div className="flex items-center gap-1.5 text-xs text-slate-400">
                <s.icon className={`h-4 w-4 ${s.color}`} />{s.label}
              </div>
              <p className="mt-1 text-lg font-semibold">{s.value}</p>
            </div>
          ))}
        </div>
        {!metrics.connected && (
          <div className="flex gap-2">
            <button type="button" onClick={handleConnect} disabled={connecting} className="btn-gradient tap-haptic flex-1 text-sm">
              {connecting ? <LoadingSpinner size="sm" /> : 'Connect Google Fit'}
            </button>
            <button type="button" onClick={async () => { const r = await connectHealthKit(); onUpdate({ healthMetrics: { ...metrics, ...r } }) }}
              className="btn-ghost tap-haptic text-sm">HealthKit</button>
          </div>
        )}
        {metrics.message && <p className="mt-2 text-xs text-slate-500">{metrics.message}</p>}
      </div>
      {metrics.history?.length > 0 && <HealthCharts history={metrics.history} />}
    </section>
  )
}
