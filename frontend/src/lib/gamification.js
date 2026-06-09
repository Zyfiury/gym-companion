/**
 * XP, streaks, levels, and achievements.
 * Level = floor(sqrt(XP / 100)) + 1
 */

export const XP_RULES = { workout: 10, meal: 5, barcode: 5, streakWeek: 50, share: 3 }

export const ACHIEVEMENT_DEFS = [
  { id: 'macro_streak_7', name: '7-day macro streak', icon: '🎯', check: (g) => g.streak >= 7 },
  { id: 'first_pr', name: '1st PR lifted', icon: '🏆', check: (_, u) => (u.personalRecords?.length ?? 0) > 0 },
  { id: 'first_barcode', name: 'First barcode scan', icon: '📱', check: (g) => g.barcodeScans >= 1 },
  { id: 'shared_5', name: 'Shared 5 posts', icon: '📢', check: (g) => g.postsShared >= 5 },
  { id: 'workout_10', name: '10 workouts logged', icon: '💪', check: (g) => g.workoutsLogged >= 10 },
  { id: 'meal_20', name: '20 meals logged', icon: '🍽️', check: (g) => g.mealsLogged >= 20 },
]

export function getDefaultGamification() {
  return {
    xp: 0,
    level: 1,
    streak: 0,
    lastActiveDate: null,
    achievements: [],
    workoutsLogged: 0,
    mealsLogged: 0,
    barcodeScans: 0,
    postsShared: 0,
    weeklyXpEarned: 0,
    weekStart: getWeekStart(),
  }
}

function getWeekStart() {
  const d = new Date()
  d.setDate(d.getDate() - d.getDay() + 1)
  return d.toISOString().slice(0, 10)
}

export function calcLevel(xp) {
  return Math.floor(Math.sqrt((xp || 0) / 100)) + 1
}

function xpForLevel(level) {
  return (level - 1) ** 2 * 100
}

function todayStr() {
  return new Date().toISOString().slice(0, 10)
}

function updateStreak(gamification) {
  const today = todayStr()
  const last = gamification.lastActiveDate
  let streak = gamification.streak || 0

  if (!last) streak = 1
  else if (last !== today) {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    streak = last === yesterday.toISOString().slice(0, 10) ? streak + 1 : 1
  }

  const weekStart = getWeekStart()
  const weeklyXpEarned = gamification.weekStart === weekStart ? (gamification.weeklyXpEarned || 0) : 0

  return { ...gamification, streak, lastActiveDate: today, weekStart, weeklyXpEarned }
}

function checkAchievements(gamification, userData) {
  const earned = new Set(gamification.achievements || [])
  for (const def of ACHIEVEMENT_DEFS) {
    if (!earned.has(def.id) && def.check(gamification, userData)) earned.add(def.id)
  }
  return [...earned]
}

export function awardXP(userData, action, extra = {}) {
  const gamification = { ...getDefaultGamification(), ...(userData.gamification || {}) }
  const xpGain = XP_RULES[action] ?? 0

  if (action === 'workout') gamification.workoutsLogged += 1
  if (action === 'meal') gamification.mealsLogged += 1
  if (action === 'barcode') gamification.barcodeScans += 1
  if (action === 'share') gamification.postsShared += 1

  gamification.xp = (gamification.xp || 0) + xpGain
  gamification.weeklyXpEarned = (gamification.weeklyXpEarned || 0) + xpGain
  gamification.level = calcLevel(gamification.xp)

  let updated = updateStreak(gamification)
  updated.achievements = checkAchievements(updated, userData)

  if (updated.streak > 0 && updated.streak % 7 === 0 && extra.streakBonus !== false) {
    const prevWeekBonus = updated.lastStreakBonusAt
    const weekKey = getWeekStart()
    if (prevWeekBonus !== weekKey) {
      updated.xp += XP_RULES.streakWeek
      updated.weeklyXpEarned += XP_RULES.streakWeek
      updated.level = calcLevel(updated.xp)
      updated.lastStreakBonusAt = weekKey
    }
  }

  return updated
}

export function getAchievementDetails(gamification) {
  const earned = new Set(gamification?.achievements || [])
  return ACHIEVEMENT_DEFS.map((def) => ({ ...def, earned: earned.has(def.id) }))
}

export function xpToNextLevel(xp) {
  const level = calcLevel(xp)
  const currentLevelXp = xpForLevel(level)
  const nextLevelXp = xpForLevel(level + 1)
  const current = xp - currentLevelXp
  const needed = nextLevelXp - currentLevelXp
  return { level, current, needed, progress: needed > 0 ? (current / needed) * 100 : 100 }
}
