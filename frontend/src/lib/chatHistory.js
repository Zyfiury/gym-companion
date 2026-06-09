import { saveChatMessages, loadChatMessages, getActiveUser } from './userStore'

export function loadChatHistory() {
  return []
}

export function saveChatHistory() {}

export function appendMessage(role, content) {
  return { id: Date.now(), role, content, ts: new Date().toISOString() }
}

export async function loadChatHistoryAsync(userId) {
  return loadChatMessages(userId || getActiveUser())
}

export function clearChatHistory(userId) {
  saveChatMessages([], userId || getActiveUser())
}
