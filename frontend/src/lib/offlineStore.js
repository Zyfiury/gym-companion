/**
 * Backward-compatible re-exports — delegates to userStore.
 */

export {
  isOnline,
  saveUserData,
  loadUserData,
  saveChatMessages,
  loadChatMessages,
  cacheWeeklyPlan,
  enqueue,
  getQueue,
  clearQueue,
  syncQueue,
  setupOfflineListeners,
  setActiveUser,
  getActiveUser,
} from './userStore'
