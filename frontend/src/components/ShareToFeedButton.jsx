import { useState } from 'react'
import { ShareIcon, CheckIcon } from '@heroicons/react/24/outline'
import { addFeedPost } from '../lib/feedStore'
import { awardXP } from '../lib/gamification'
import { useAuth } from '../context/AuthContext'
import LoadingSpinner from './LoadingSpinner'

export default function ShareToFeedButton({ type, content, userData, onUpdate }) {
  const { userId, displayName } = useAuth()
  const [shared, setShared] = useState(false)
  const [loading, setLoading] = useState(false)

  const handleShare = async () => {
    if (shared || loading) return
    setLoading(true)
    await addFeedPost({ type, content, authorId: userId, displayName })
    const gamification = awardXP(userData, 'share')
    onUpdate?.({ gamification })
    setShared(true)
    setLoading(false)
  }

  return (
    <button type="button" onClick={handleShare} disabled={shared || loading}
      className="btn-ghost tap-haptic flex items-center gap-1.5 text-sm" data-testid="share-to-feed">
      {loading ? <LoadingSpinner size="sm" /> : shared ? (
        <><CheckIcon className="h-4 w-4 text-green-400" /> Shared!</>
      ) : (
        <><ShareIcon className="h-4 w-4" /> Share to Feed</>
      )}
    </button>
  )
}
