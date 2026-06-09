/**
 * Bridge to OpenClaw agent sessions — per-user aware.
 */

import { enqueue, isOnline, getActiveUser } from './userStore'
import { getDefaultGamification } from './gamification'
import { getDefaultHealthMetrics } from './healthData'

async function sendToGateway(message, userId) {
  const gatewayUrl = import.meta.env.VITE_OPENCLAW_GATEWAY_URL
  if (!gatewayUrl) return { ok: true, queued: true }
  try {
    const base = gatewayUrl.replace(/^ws/, 'http').replace(/\/$/, '')
    const res = await fetch(`${base}/api/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, userId }),
    })
    if (res.ok) return await res.json()
  } catch { /* offline */ }
  return { ok: true, queued: true }
}

export async function sendSessionMessage(message, userId) {
  const uid = userId || getActiveUser()
  const tagged = uid ? `${message}` : message

  if (!isOnline()) {
    await enqueue({ type: 'message', message: tagged, userId: uid }, uid)
    return { ok: true, queued: true }
  }
  return sendToGateway(tagged, uid)
}

export async function sendChatCommand(text, userData, userId) {
  const uid = userId || userData.userId || getActiveUser()
  const payload = {
    type: 'CHAT_COMMAND',
    userId: uid,
    message: text,
    userSnapshot: {
      goal: userData.goal,
      weight: userData.weight,
      height: userData.height,
      age: userData.age,
      tdee: userData.tdee,
      dailyMacrosLogged: userData.dailyMacrosLogged,
      foodLog: userData.foodLog?.slice(-5),
      gamification: userData.gamification,
    },
  }
  if (!isOnline()) {
    await enqueue({ type: 'CHAT_COMMAND', payload }, uid)
  } else {
    await sendSessionMessage(`CHAT_COMMAND: ${JSON.stringify(payload)}`, uid)
  }
  return payload
}

export async function fetchUserData() {
  const { loadUserData } = await import('./userStore')
  const uid = getActiveUser()
  if (!uid) return getDefaultUserData()
  return loadUserData(uid)
}

export function getDefaultUserData() {
  return {
    goal: '',
    weight: 70,
    height: 175,
    age: 30,
    tdee: 2200,
    weeklyBudget: 50,
    nutritionMode: 'cook_myself',
    dietaryRestrictions: 'none',
    favouriteMeals: [],
    weeklyProgressLog: [],
    foodLog: [],
    profileComplete: false,
    gamification: getDefaultGamification(),
    healthMetrics: getDefaultHealthMetrics(),
    quickStats: { steps: 0, water: 0, caloriesBurned: 0 },
    weeklyPlan: {
      macros: { calories: 2200, protein: 140, carbs: 220, fat: 65 },
      workouts: [
        { day: 'Mon', focus: 'Push', exercises: ['Bench Press 4×8', 'OHP 3×10', 'Tricep Pushdown 3×12'] },
        { day: 'Tue', focus: 'Pull', exercises: ['Deadlift 4×5', 'Rows 4×10', 'Face Pulls 3×15'] },
        { day: 'Wed', focus: 'Legs', exercises: ['Squat 4×8', 'RDL 3×10', 'Leg Curl 3×12'] },
        { day: 'Thu', focus: 'Push', exercises: ['Incline DB 4×10', 'Lateral Raise 3×15'] },
        { day: 'Fri', focus: 'Pull', exercises: ['Pull-ups 4×AMRAP', 'Curls 3×12'] },
        { day: 'Sat', focus: 'Legs', exercises: ['Leg Press 4×12', 'Calf Raise 4×15'] },
        { day: 'Sun', focus: 'Rest', exercises: ['Walk 30 min', 'Stretch 15 min'] },
      ],
      meals: [
        { mealType: 'Breakfast', name: 'Greek Yogurt Bowl', description: 'High protein start', macros: { calories: 420, protein: 35, carbs: 45, fat: 10 }, youtubeVideoId: null, steps: ['Add yogurt', 'Top with berries'] },
        { mealType: 'Lunch', name: 'Chicken Rice Bowl', description: 'Balanced midday meal', macros: { calories: 650, protein: 45, carbs: 70, fat: 18 }, youtubeVideoId: null, steps: ['Grill chicken', 'Serve over rice'] },
      ],
      shoppingList: { supermarket: 'Tesco', totalEstimatedCost: '£12.40', items: [] },
    },
    dailyMacrosLogged: { calories: 0, protein: 0, carbs: 0, fat: 0 },
    budgetSpent: 0,
    weightHistory: [{ date: new Date().toISOString().slice(0, 10), weight: 70 }],
    measurements: [],
    personalRecords: [],
    recentInsights: [],
  }
}

export function saveUserDataLocally() {
  /* deprecated — use AuthContext.updateUserData */
}

export function syncUserToMarkdown(data, userId) {
  sendSessionMessage(`USER_MD_SYNC: ${JSON.stringify({ type: 'USER_MD_SYNC', userId, data })}`, userId)
}
