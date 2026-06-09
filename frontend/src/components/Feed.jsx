import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { NewspaperIcon, TrophyIcon, HeartIcon, ChatBubbleLeftIcon } from '@heroicons/react/24/outline'
import { HeartIcon as HeartSolid } from '@heroicons/react/24/solid'
import { getFeedPosts, toggleLike, addComment, getLeaderboard } from '../lib/feedStore'
import { useAuth } from '../context/AuthContext'
import LoadingSpinner from './LoadingSpinner'

export default function Feed() {
  const { userId, displayName } = useAuth()
  const [tab, setTab] = useState('all')
  const [posts, setPosts] = useState([])
  const [leaderboard, setLeaderboard] = useState([])
  const [loading, setLoading] = useState(true)
  const [commentOn, setCommentOn] = useState(null)
  const [commentText, setCommentText] = useState('')

  const load = async () => {
    setLoading(true)
    const [p, lb] = await Promise.all([
      getFeedPosts(userId, tab),
      getLeaderboard(userId),
    ])
    setPosts(p)
    setLeaderboard(lb)
    setLoading(false)
  }

  useEffect(() => { load() }, [tab, userId])

  const handleLike = async (postId) => {
    await toggleLike(postId, userId)
    load()
  }

  const handleComment = async (postId) => {
    if (!commentText.trim()) return
    await addComment(postId, userId, commentText.trim(), displayName)
    setCommentText('')
    setCommentOn(null)
    load()
  }

  const typeEmoji = { workout: '🏋️', meal: '🍽️', general: '📝' }

  return (
    <motion.section initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="space-y-4" data-testid="feed">
      <div className="card-glow">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <NewspaperIcon className="h-5 w-5 text-violet-400" />
            <h2 className="font-semibold">Feed</h2>
          </div>
          <div className="flex rounded-lg bg-white/5 p-0.5">
            {['all', 'mine'].map((t) => (
              <button key={t} type="button" onClick={() => setTab(t)}
                className={`tap-haptic rounded-md px-3 py-1 text-xs capitalize ${tab === t ? 'bg-violet-500/30 text-violet-300' : 'text-slate-400'}`}>
                {t === 'all' ? 'Public' : 'My Posts'}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="flex justify-center py-8"><LoadingSpinner /></div>
        ) : posts.length === 0 ? (
          <p className="py-6 text-center text-sm text-slate-500">No posts yet — complete a workout or log a meal to share!</p>
        ) : (
          <div className="space-y-3">
            <AnimatePresence>
              {posts.map((post) => {
                const liked = post.likes?.includes(userId)
                return (
                  <motion.div key={post.id} layout initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}
                    className="rounded-xl border border-white/5 bg-white/5 p-3">
                    <div className="mb-2 flex items-center gap-2">
                      <span className="text-xl">{post.avatar}</span>
                      <div className="flex-1">
                        <p className="text-sm font-medium">{post.authorName}</p>
                        <p className="text-xs text-slate-500">{new Date(post.ts).toLocaleString()}</p>
                      </div>
                      <span>{typeEmoji[post.type] || '📝'}</span>
                    </div>
                    <p className="text-sm text-slate-300">{post.content}</p>
                    <div className="mt-2 flex items-center gap-4">
                      <button type="button" onClick={() => handleLike(post.id)} className="tap-haptic flex items-center gap-1 text-xs text-slate-400 hover:text-red-400">
                        {liked ? <HeartSolid className="h-4 w-4 text-red-400" /> : <HeartIcon className="h-4 w-4" />}
                        {post.likes?.length || 0}
                      </button>
                      <button type="button" onClick={() => setCommentOn(commentOn === post.id ? null : post.id)} className="tap-haptic flex items-center gap-1 text-xs text-slate-400 hover:text-violet-400">
                        <ChatBubbleLeftIcon className="h-4 w-4" />
                        {post.comments?.length || 0}
                      </button>
                    </div>
                    {post.comments?.length > 0 && (
                      <div className="mt-2 space-y-1 border-t border-white/5 pt-2">
                        {post.comments.map((c) => (
                          <p key={c.id} className="text-xs text-slate-400"><span className="font-medium text-slate-300">{c.authorName}:</span> {c.text}</p>
                        ))}
                      </div>
                    )}
                    {commentOn === post.id && (
                      <div className="mt-2 flex gap-2">
                        <input value={commentText} onChange={(e) => setCommentText(e.target.value)} placeholder="Add a comment…" className="input-field flex-1 text-sm" onKeyDown={(e) => e.key === 'Enter' && handleComment(post.id)} />
                        <button type="button" onClick={() => handleComment(post.id)} className="btn-gradient tap-haptic text-sm">Post</button>
                      </div>
                    )}
                  </motion.div>
                )
              })}
            </AnimatePresence>
          </div>
        )}
      </div>

      <div className="card">
        <div className="mb-3 flex items-center gap-2">
          <TrophyIcon className="h-5 w-5 text-amber-400" />
          <h3 className="font-semibold">Weekly leaderboard</h3>
        </div>
        <div className="space-y-2">
          {leaderboard.map((entry, i) => (
            <div key={entry.id} className={`flex items-center gap-3 rounded-lg px-3 py-2 ${entry.name === 'You' ? 'bg-violet-500/10' : 'bg-white/5'}`}>
              <span className="w-5 text-center text-sm font-bold text-slate-400">#{i + 1}</span>
              <span className="text-lg">{entry.avatar}</span>
              <span className="flex-1 text-sm font-medium">{entry.name}</span>
              <span className="text-sm text-violet-400">{entry.weeklyXp} XP</span>
              <span className="text-xs text-slate-500">Lv.{entry.level}</span>
            </div>
          ))}
        </div>
      </div>
    </motion.section>
  )
}
