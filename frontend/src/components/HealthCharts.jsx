import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'

export default function HealthCharts({ history = [] }) {
  if (!history.length) return null

  const data = history.map((h) => ({
    date: h.date.slice(5),
    steps: h.steps,
    sleep: h.sleepHours,
    hr: h.heartRate,
    cal: h.caloriesBurned,
  }))

  return (
    <div className="space-y-4">
      <ChartBlock title="Steps (7 days)" data={data} dataKey="steps" color="#8b5cf6" unit="" />
      <ChartBlock title="Sleep hours" data={data} dataKey="sleep" color="#6366f1" unit="h" />
      <ChartBlock title="Heart rate" data={data} dataKey="hr" color="#ef4444" unit=" bpm" />
    </div>
  )
}

function ChartBlock({ title, data, dataKey, color, unit }) {
  return (
    <div className="card">
      <h4 className="mb-3 text-sm font-medium text-slate-400">{title}</h4>
      <ResponsiveContainer width="100%" height={140}>
        <AreaChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
          <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#64748b' }} />
          <YAxis tick={{ fontSize: 10, fill: '#64748b' }} width={35} />
          <Tooltip
            contentStyle={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, fontSize: 12 }}
            formatter={(v) => [`${v}${unit}`, title]}
          />
          <Area type="monotone" dataKey={dataKey} stroke={color} fill={color} fillOpacity={0.15} strokeWidth={2} />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
