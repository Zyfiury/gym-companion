/**
 * Social feed — global posts with likes & comments in IndexedDB.
 */

import { getAllFeedPosts, saveAllFeedPosts, enqueue, isOnline } from './userStore'
import { getAccountById } from './auth'

async function syncToAgent(post, userId) {
  const payload = { type: 'FEED_SYNC', userId, post }
  if (!isOnline()) {
    await enqueue(payload, userId)
    return
  }
  const gatewayUrl = import.meta.env.VITE_OPENCLAW_GATEWAY_URL
  if (gatewayUrl) {
    try {
      const base = gatewayUrl.replace(/^ws/, 'http').replace(/\/$/, '')
      await fetch(`${base}/api/message`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: `FEED_SYNC: ${JSON.stringify(payload)}`, userId }),
      })
    } catch {
      await enqueue(payload, userId)
    }
  }
}

async function enrichPost(post) {
  const account = await getAccountById(post.authorId)
  return {
    ...post,
    authorName: post.authorId === post.viewerId ? 'You' : (account?.displayName || 'User'),
    avatar: post.authorId === post.viewerId ? '⭐' : '💪',
  }
}

export async function getFeedPosts(viewerId, filter = 'all') {
  const all = await getAllFeedPosts()
  const enriched = await Promise.all(all.map(async (p) => enrichPost({ ...p, viewerId })))
  const sorted = enriched.sort((a, b) => new Date(b.ts) - new Date(a.ts))
  if (filter === 'mine') return sorted.filter((p) => p.authorId === viewerId)
  return sorted
}

export async function addFeedPost({ type, content, imageUrl, authorId, displayName }) {
  const post = {
    id: `post_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    authorId,
    authorName: displayName || 'User',
    avatar: '⭐',
    type,
    content,
    imageUrl: imageUrl || null,
    ts: new Date().toISOString(),
    likes: [],
    comments: [],
  }
  const posts = await getAllFeedPosts()
  posts.unshift(post)
  await saveAllFeedPosts(posts)
  await syncToAgent(post, authorId)
  return post
}

export async function toggleLike(postId, userId) {
  const posts = await getAllFeedPosts()
  const post = posts.find((p) => p.id === postId)
  if (!post) return
  if (!post.likes) post.likes = []
  const idx = post.likes.indexOf(userId)
  if (idx >= 0) post.likes.splice(idx, 1)
  else post.likes.push(userId)
  await saveAllFeedPosts(posts)
  return post
}

export async function addComment(postId, userId, text, displayName) {
  const posts = await getAllFeedPosts()
  const post = posts.find((p) => p.id === postId)
  if (!post) return
  if (!post.comments) post.comments = []
  const comment = { id: `c_${Date.now()}`, authorId: userId, authorName: displayName, text, ts: new Date().toISOString() }
  post.comments.push(comment)
  await saveAllFeedPosts(posts)
  return comment
}

export async function getUserPostCount(userId) {
  const posts = await getAllFeedPosts()
  return posts.filter((p) => p.authorId === userId).length
}

export { getLeaderboardData as getLeaderboard } from './userStore'
