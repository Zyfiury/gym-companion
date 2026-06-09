/**
 * Per-user namespaced IndexedDB stores + agent sync.
 */

import localforage from 'localforage'
import { getSession } from './auth'
import { getDefaultUserData } from './sessions'

let activeUserId = null

const globalFeedStore = localforage.createInstance({ name: 'gymapp_global', storeName: 'feed' })
const globalQueueStore = localforage.createInstance({ name: 'gymapp_global', storeName: 'queue' })

function userInstance(userId, storeName) {
  return localforage.createInstance({ name: `gymapp_${userId}`, storeName })
}

export function setActiveUser(userId) {
  activeUserId = userId
}

export function getActiveUser() {
  return activeUserId || getSession()?.userId || null
}

function uid(userId) {
  return userId || getActiveUser()
}

async function sendToGateway(message, userId) {
  const gatewayUrl = import.meta.env.VITE_OPENCLAW_GATEWAY_URL
  if (!gatewayUrl) return false
  try {
    const base = gatewayUrl.replace(/^ws/, 'http').replace(/\/$/, '')
    const res = await fetch(`${base}/api/message`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, userId }),
    })
    return res.ok
  } catch {
    return false
  }
}

export function isOnline() {
  return typeof navigator !== 'undefined' ? navigator.onLine : true
}

// ── User data ──

export async function loadUserData(userId) {
  const id = uid(userId)
  if (!id) return null
  const store = userInstance(id, 'data')
  const data = await store.getItem('profile')
  if (data) return { ...data, userId: id }
  const fresh = { ...getDefaultUserData(), userId: id, profileComplete: false }
  await store.setItem('profile', fresh)
  return fresh
}

export async function saveUserData(data, userId) {
  const id = uid(userId)
  if (!id) return
  const store = userInstance(id, 'data')
  const payload = { ...data, userId: id }
  await store.setItem('profile', payload)

  const syncMsg = `USER_MD_SYNC: ${JSON.stringify({ type: 'USER_MD_SYNC', userId: id, data: payload })}`
  if (isOnline()) {
    await sendToGateway(syncMsg, id)
  } else {
    await enqueue({ type: 'USER_MD_SYNC', userId: id, data: payload }, id)
  }
}

// ── Chat ──

export async function loadChatMessages(userId) {
  const id = uid(userId)
  if (!id) return []
  return (await userInstance(id, 'chat').getItem('history')) || []
}

export async function saveChatMessages(messages, userId) {
  const id = uid(userId)
  if (!id) return
  const trimmed = messages.slice(-100)
  await userInstance(id, 'chat').setItem('history', trimmed)

  if (isOnline()) {
    await sendToGateway(`CHAT_SYNC: ${JSON.stringify({ userId: id, messages: trimmed })}`, id)
  }
}

// ── Plans cache ──

export async function cacheWeeklyPlan(plan, userId) {
  const id = uid(userId)
  if (!id) return
  const store = userInstance(id, 'plans')
  const plans = (await store.getItem('weekly')) || []
  const entry = { date: new Date().toISOString().slice(0, 10), plan }
  const filtered = plans.filter((p) => p.date !== entry.date)
  filtered.push(entry)
  await store.setItem('weekly', filtered.sort((a, b) => b.date.localeCompare(a.date)).slice(0, 7))
}

// ── Health cache ──

export async function saveHealthCache(metrics, userId) {
  const id = uid(userId)
  if (!id) return
  await userInstance(id, 'health').setItem('cache', { ...metrics, cachedAt: Date.now() })
}

export async function loadHealthCache(userId) {
  const id = uid(userId)
  if (!id) return null
  return userInstance(id, 'health').getItem('cache')
}

// ── Global feed (all users) ──

export async function getAllFeedPosts() {
  return (await globalFeedStore.getItem('posts')) || []
}

export async function saveAllFeedPosts(posts) {
  await globalFeedStore.setItem('posts', posts)
}

// ── Sync queue (per user) ──

export async function enqueue(item, userId) {
  const id = uid(userId)
  const store = id ? userInstance(id, 'queue') : globalQueueStore
  const queue = (await store.getItem('pending')) || []
  queue.push({ ...item, ts: Date.now() })
  await store.setItem('pending', queue)
}

export async function getQueue(userId) {
  const id = uid(userId)
  const store = id ? userInstance(id, 'queue') : globalQueueStore
  return (await store.getItem('pending')) || []
}

export async function clearQueue(userId) {
  const id = uid(userId)
  const store = id ? userInstance(id, 'queue') : globalQueueStore
  await store.setItem('pending', [])
}

export async function syncQueue(userId) {
  if (!isOnline()) return
  const id = uid(userId)
  const queue = await getQueue(id)
  if (!queue.length) return

  const failed = []
  for (const item of queue) {
    let msg
    if (item.type === 'CHAT_COMMAND') {
      msg = `CHAT_COMMAND: ${JSON.stringify({ ...item.payload, userId: id })}`
    } else if (item.type === 'USER_MD_SYNC') {
      msg = `USER_MD_SYNC: ${JSON.stringify(item)}`
    } else if (item.type === 'FEED_SYNC') {
      msg = `FEED_SYNC: ${JSON.stringify(item)}`
    } else {
      msg = item.message || JSON.stringify(item)
    }
    const ok = await sendToGateway(msg, id)
    if (!ok) failed.push(item)
  }
  if (failed.length) {
    const store = id ? userInstance(id, 'queue') : globalQueueStore
    await store.setItem('pending', failed)
  } else {
    await clearQueue(id)
  }
}

export function setupOfflineListeners(onStatusChange, userId) {
  const handler = () => {
    onStatusChange?.(isOnline())
    if (isOnline()) syncQueue(userId || getActiveUser())
  }
  window.addEventListener('online', handler)
  window.addEventListener('offline', handler)
  return () => {
    window.removeEventListener('online', handler)
    window.removeEventListener('offline', handler)
  }
}

// ── Leaderboard: aggregate XP from all users ──

export async function getLeaderboardData(currentUserId) {
  const { getAllAccounts } = await import('./auth')
  const accounts = await getAllAccounts()
  const entries = []

  for (const account of accounts) {
    const data = await loadUserData(account.userId)
    const g = data?.gamification || {}
    entries.push({
      id: account.userId,
      name: account.userId === currentUserId ? 'You' : account.displayName,
      avatar: account.userId === currentUserId ? '⭐' : '💪',
      weeklyXp: g.weeklyXpEarned || g.xp || 0,
      totalXp: g.xp || 0,
      level: g.level || 1,
    })
  }

  return entries.sort((a, b) => b.weeklyXp - a.weeklyXp).slice(0, 10)
}
