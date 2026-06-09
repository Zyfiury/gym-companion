/**
 * CHAT_COMMAND processor — local NL + Groq + nutrition API.
 */

import { searchFood, scaleMacros, createFoodLogEntry, addToFoodLog } from './nutritionApi'
import { awardXP } from './gamification'
import { generateInsightWithGroq, generateLocalInsights } from './insights'

const DAY_MAP = {
  monday: 'Mon', mon: 'Mon',
  tuesday: 'Tue', tue: 'Tue',
  wednesday: 'Wed', wed: 'Wed',
  thursday: 'Thu', thu: 'Thu',
  friday: 'Fri', fri: 'Fri',
  saturday: 'Sat', sat: 'Sat',
  sunday: 'Sun', sun: 'Sun',
}

function calcTdee(weight, height, age, goal, baseTdee) {
  let tdee = baseTdee || 2200
  if (goal === 'cut') tdee = Math.round(tdee - 500)
  else if (goal === 'bulk') tdee = Math.round(tdee + 300)
  return tdee
}

function generateUpperLowerPlan() {
  return [
    { day: 'Mon', focus: 'Upper A', exercises: ['Bench Press 4×6-8', 'Barbell Row 4×8', 'OHP 3×10', 'Lat Pulldown 3×12'] },
    { day: 'Tue', focus: 'Lower A', exercises: ['Squat 4×6-8', 'RDL 3×10', 'Leg Press 3×12', 'Calf Raise 4×15'] },
    { day: 'Wed', focus: 'Rest', exercises: ['Walk 30 min', 'Mobility 15 min'] },
    { day: 'Thu', focus: 'Upper B', exercises: ['Incline DB Press 4×10', 'Cable Row 4×10', 'Lateral Raise 3×15', 'Tricep Extension 3×12'] },
    { day: 'Fri', focus: 'Lower B', exercises: ['Deadlift 4×5', 'Bulgarian Split Squat 3×10', 'Leg Curl 3×12', 'Abs 3×15'] },
    { day: 'Sat', focus: 'Active', exercises: ['Light cardio 20 min'] },
    { day: 'Sun', focus: 'Rest', exercises: ['Full rest or yoga'] },
  ]
}

function generateHighProteinMeals() {
  return [
    { mealType: 'Breakfast', name: 'Protein Oats', description: '40g protein start', macros: { calories: 450, protein: 40, carbs: 50, fat: 12 }, youtubeVideoId: 'dQw4w9WgXcQ', steps: ['Cook oats with milk', 'Stir in whey', 'Top with berries'] },
    { mealType: 'Lunch', name: 'Grilled Chicken Bowl', description: 'Lean lunch', macros: { calories: 550, protein: 50, carbs: 45, fat: 15 }, youtubeVideoId: 'dQw4w9WgXcQ', steps: ['Grill 200g chicken', 'Serve with rice and greens'] },
    { mealType: 'Dinner', name: 'Salmon & Quinoa', description: 'Omega-3 dinner', macros: { calories: 520, protein: 42, carbs: 40, fat: 18 }, youtubeVideoId: 'dQw4w9WgXcQ', steps: ['Bake salmon 180°C 15min', 'Cook quinoa'] },
  ]
}

async function handleFoodLog(text, userData) {
  const logMatch = text.match(/log\s+(\d+(?:\.\d+)?)\s*g?\s+(.+)/i)
  if (!logMatch) return null

  const grams = parseFloat(logMatch[1])
  const query = logMatch[2].trim()
  const results = await searchFood(query)

  if (!results.length) {
    return { patch: {}, reply: `Couldn't find "${query}" in Open Food Facts. Try a more specific name.` }
  }

  const food = results[0]
  const macros = scaleMacros(food.per100g, grams)
  const entry = createFoodLogEntry(food, grams, macros)
  const { foodLog, dailyMacrosLogged } = addToFoodLog(userData, entry)
  const gamification = awardXP({ ...userData, foodLog }, 'meal')

  const target = userData.weeklyPlan?.macros?.calories ?? userData.tdee
  return {
    patch: { foodLog, dailyMacrosLogged, gamification },
    reply: `✅ Logged **${grams}g ${food.name}**\n• ${macros.calories} kcal · P ${macros.protein}g · C ${macros.carbs}g · F ${macros.fat}g\n\nToday: **${dailyMacrosLogged.calories}/${target} kcal** (+5 XP)`,
  }
}

export async function parseAndExecute(text, userData) {
  const lower = text.toLowerCase()
  const patch = {}
  const changes = []
  let reply = ''

  const foodResult = await handleFoodLog(text, userData)
  if (foodResult) return foodResult

  if (/what insights|how am i doing|weekly review|give me insights/i.test(lower)) {
    const insight = await generateInsightWithGroq(userData, [])
    return { patch: {}, reply: `📊 **Your personalised insights:**\n\n${insight}` }
  }

  const weightMatch = lower.match(/(?:weight|weigh)\s*(?:to|is|=)?\s*(\d+(?:\.\d+)?)\s*kg?/i) || lower.match(/(\d+(?:\.\d+)?)\s*kg/)
  if (weightMatch && (lower.includes('weight') || lower.includes('kg') || lower.includes('update') || lower.includes('set'))) {
    patch.weight = parseFloat(weightMatch[1])
    changes.push(`weight to ${patch.weight}kg`)
  }

  const goalMatch = lower.match(/goal\s*(?:to|is|=)?\s*(cut|bulk|maintain)/i)
    || lower.match(/(?:change|set).*(cut|bulk|maintain)/i)
    || lower.match(/(cutting|bulking)/i)
  if (goalMatch) {
    let g = goalMatch[1].toLowerCase()
    if (g === 'cutting') g = 'cut'
    if (g === 'bulking') g = 'bulk'
    if (['cut', 'bulk', 'maintain'].includes(g)) {
      patch.goal = g
      changes.push(`goal to '${patch.goal}'`)
    }
  }

  if (/budget\s*(?:to|is|=)?\s*£?(\d+)/i.test(lower)) {
    const m = lower.match(/budget\s*(?:to|is|=)?\s*£?(\d+)/i)
    patch.weeklyBudget = Number(m[1])
    changes.push(`weekly budget to £${patch.weeklyBudget}`)
  }

  if (changes.length) {
    const goal = patch.goal ?? userData.goal
    const tdee = calcTdee(patch.weight ?? userData.weight, userData.height, userData.age, goal, userData.tdee)
    patch.tdee = tdee
    if (userData.weeklyPlan?.macros) {
      patch.weeklyPlan = {
        ...userData.weeklyPlan,
        macros: { ...userData.weeklyPlan.macros, calories: tdee },
      }
    }
    reply = `✅ Updated your ${changes.join(' and ')}. Your daily calorie target is now **${tdee} kcal**.`
    if (patch.goal === 'cut') reply += ' Want me to generate a cutting workout plan?'
    else if (patch.goal === 'bulk') reply += ' Want me to generate a bulking workout plan?'
    return { patch, reply }
  }

  if (/calories.*(eaten|had|today)|how many calories/i.test(lower)) {
    const logged = userData.dailyMacrosLogged ?? { calories: 0 }
    const target = userData.weeklyPlan?.macros?.calories ?? userData.tdee
    reply = `You've logged **${logged.calories} kcal** today out of your **${target} kcal** target (${Math.round((logged.calories / target) * 100)}%).`
    return { patch: {}, reply }
  }

  const dayKey = Object.keys(DAY_MAP).find((d) => lower.includes(d))
  if (dayKey && (lower.includes('workout') || lower.includes('training') || lower.includes('exercise'))) {
    const day = DAY_MAP[dayKey]
    const w = userData.weeklyPlan?.workouts?.find((x) => x.day === day)
    if (w) {
      reply = `**${day} — ${w.focus}**\n${w.exercises.map((e) => `• ${e}`).join('\n')}`
    } else {
      reply = `No workout found for ${day}. Ask me to generate a plan!`
    }
    return { patch: {}, reply }
  }

  if (/high.?protein.*meal|meal plan.*today|generate.*meal/i.test(lower)) {
    const meals = generateHighProteinMeals()
    const protein = Math.round((userData.weight ?? 70) * 2)
    patch.weeklyPlan = {
      ...userData.weeklyPlan,
      meals,
      macros: { calories: userData.tdee ?? 2200, protein, carbs: 200, fat: 65 },
    }
    reply = `Here's your high-protein plan for today (~${protein}g protein):\n${meals.map((m) => `• **${m.mealType}:** ${m.name} (${m.macros.protein}g P)`).join('\n')}`
    return { patch, reply }
  }

  if (/generate|create|yes.*plan|workout plan|upper.?lower|split/i.test(lower)) {
    const workouts = generateUpperLowerPlan()
    patch.weeklyPlan = { ...userData.weeklyPlan, workouts }
    reply = `Here's your **4-day upper/lower split**:\n${workouts.filter((w) => w.focus !== 'Rest' && w.focus !== 'Active').map((w) => `**${w.day}** — ${w.focus}: ${w.exercises.slice(0, 2).join(', ')}…`).join('\n')}\n\nCheck the Workout tab for full details.`
    return { patch, reply }
  }

  if (/hello|hi|hey/i.test(lower)) {
    reply = `Hey! I'm your gym companion. Try:\n• "Log 200g chicken breast"\n• "Set my weight to 72kg"\n• "What insights do you have for me?"\n• "Show workout for Thursday"`
    return { patch: {}, reply }
  }

  return null
}

async function callGroq(userMessage, userData, history) {
  const apiKey = import.meta.env.VITE_GROQ_API_KEY
  if (!apiKey) return null

  const system = `You are a gym & nutrition AI assistant. User profile: ${JSON.stringify({ goal: userData.goal, weight: userData.weight, tdee: userData.tdee, streak: userData.gamification?.streak })}. Respond concisely in plain English. If user asks to update profile, confirm changes. Use markdown sparingly.`

  const messages = [
    { role: 'system', content: system },
    ...history.slice(-8).map((m) => ({ role: m.role === 'user' ? 'user' : 'assistant', content: m.content })),
    { role: 'user', content: userMessage },
  ]

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages,
        max_tokens: 512,
        temperature: 0.6,
      }),
    })
    if (!res.ok) return null
    const data = await res.json()
    return data.choices?.[0]?.message?.content?.trim() || null
  } catch {
    return null
  }
}

export async function processChatCommand(text, userData, history = []) {
  const local = await parseAndExecute(text, userData)
  if (local) return local

  const groqReply = await callGroq(text, userData, history)
  if (groqReply) return { patch: {}, reply: groqReply }

  return {
    patch: {},
    reply: "I can help log food, update your profile, show workouts, track calories, or generate plans. Try: \"Log 200g chicken breast\" or \"What insights do you have for me?\"",
  }
}
