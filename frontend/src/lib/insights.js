/**
 * Personalised insights — local analysis + Groq, per-user.
 */

function analyzeFoodLog(foodLog) {
  if (!foodLog?.length) return []
  const byDay = {}
  for (const entry of foodLog) {
    const day = new Date(entry.date).getDay()
    byDay[day] = (byDay[day] || 0) + entry.calories
  }
  const insights = []
  const fri = byDay[5]
  const avg = Object.values(byDay).reduce((a, b) => a + b, 0) / Object.keys(byDay).length
  if (fri && fri > avg * 1.2) insights.push(`You tend to overeat on Fridays (${Math.round(fri)} kcal avg) — try a protein-rich snack before dinner.`)
  return insights
}

function analyzeWorkouts(userData) {
  const insights = []
  const workouts = userData.weeklyPlan?.workouts || []
  const trainingDays = workouts.filter((w) => w.focus !== 'Rest' && w.focus !== 'Active').length
  if (trainingDays >= 5) insights.push('High training volume — ensure adequate protein and sleep.')
  if (trainingDays <= 3) insights.push('Consider adding 1 more session for better progressive overload.')
  return insights
}

function analyzeProgress(userData) {
  const insights = []
  const history = userData.weightHistory || []
  if (history.length >= 2) {
    const recent = history.slice(-2)
    const diff = recent[1].weight - recent[0].weight
    if (userData.goal === 'cut' && diff > 0) insights.push('Weight trending up during a cut — review calorie intake.')
    if (userData.goal === 'bulk' && diff < 0) insights.push('Weight dropping during bulk — add 150–200 kcal.')
  }
  return insights
}

export function generateLocalInsights(userData) {
  const insights = [...analyzeFoodLog(userData.foodLog), ...analyzeWorkouts(userData), ...analyzeProgress(userData)]
  if (!insights.length) insights.push('Keep logging meals and workouts — I\'ll have personalised tips once there\'s more data.')
  return insights
}

export function shouldShowMondayInsight(userId) {
  const today = new Date()
  if (today.getDay() !== 1) return false
  const key = `gymapp_last_monday_insight_${userId || 'anon'}`
  const todayStr = today.toISOString().slice(0, 10)
  if (localStorage.getItem(key) === todayStr) return false
  localStorage.setItem(key, todayStr)
  return true
}

export async function generateInsightWithGroq(userData, history, userId) {
  const apiKey = import.meta.env.VITE_GROQ_API_KEY
  const localInsights = generateLocalInsights(userData)

  if (!apiKey) return localInsights.map((i) => `💡 ${i}`).join('\n\n')

  const context = {
    userId,
    goal: userData.goal,
    weight: userData.weight,
    foodLogDays: userData.foodLog?.length ?? 0,
    streak: userData.gamification?.streak ?? 0,
    localInsights,
    recentChat: history.slice(-8).map((m) => `${m.role}: ${m.content}`),
    weeklyProgress: userData.weeklyProgressLog?.slice(-7),
  }

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { role: 'system', content: 'You are a gym coach giving brief, actionable weekly insights. Warm tone. 2-3 bullet points max.' },
          { role: 'user', content: `Analyze and give personalised insights:\n${JSON.stringify(context)}` },
        ],
        max_tokens: 300,
        temperature: 0.7,
      }),
    })
    if (!res.ok) return localInsights.map((i) => `💡 ${i}`).join('\n\n')
    const data = await res.json()
    const reply = data.choices?.[0]?.message?.content?.trim()
    if (reply) {
      const insights = userData.recentInsights || []
      insights.unshift({ text: reply, date: new Date().toISOString() })
      userData.recentInsights = insights.slice(0, 10)
    }
    return reply || localInsights.join('\n')
  } catch {
    return localInsights.map((i) => `💡 ${i}`).join('\n\n')
  }
}
