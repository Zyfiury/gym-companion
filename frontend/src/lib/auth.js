/**
 * User accounts — IndexedDB storage with SHA-256 password hashing.
 */

import localforage from 'localforage'

const accountsStore = localforage.createInstance({ name: 'gymapp', storeName: 'accounts' })
const SESSION_KEY = 'gymapp_session'

export async function hashPassword(password) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(password))
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, '0')).join('')
}

function generateUserId() {
  return `user_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`
}

async function getAccounts() {
  return (await accountsStore.getItem('list')) || []
}

async function saveAccounts(accounts) {
  await accountsStore.setItem('list', accounts)
}

export async function signUp({ email, password, displayName }) {
  const normalized = email.trim().toLowerCase()
  const accounts = await getAccounts()
  if (accounts.find((a) => a.email === normalized)) {
    throw new Error('An account with this email already exists')
  }
  if (password.length < 6) throw new Error('Password must be at least 6 characters')

  const account = {
    userId: generateUserId(),
    email: normalized,
    passwordHash: await hashPassword(password),
    displayName: displayName?.trim() || normalized.split('@')[0],
    createdAt: new Date().toISOString(),
  }
  accounts.push(account)
  await saveAccounts(accounts)
  return account
}

export async function login({ email, password }) {
  const normalized = email.trim().toLowerCase()
  const accounts = await getAccounts()
  const hash = await hashPassword(password)
  const account = accounts.find((a) => a.email === normalized && a.passwordHash === hash)
  if (!account) throw new Error('Invalid email or password')
  return account
}

export function saveSession(account) {
  localStorage.setItem(SESSION_KEY, JSON.stringify({
    userId: account.userId,
    email: account.email,
    displayName: account.displayName,
  }))
}

export function getSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null')
  } catch {
    return null
  }
}

export function clearSession() {
  localStorage.removeItem(SESSION_KEY)
}

export async function getAllAccounts() {
  return getAccounts()
}

export async function getAccountById(userId) {
  const accounts = await getAccounts()
  return accounts.find((a) => a.userId === userId) || null
}
