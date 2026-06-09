import { motion, AnimatePresence } from 'framer-motion'
import { XMarkIcon } from '@heroicons/react/24/solid'

export default function ExerciseVideoModal({ open, onClose, video }) {
  if (!video) return null

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.9 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0.9 }}
            className="w-full max-w-lg overflow-hidden rounded-2xl bg-surface-card"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
              <h3 className="font-semibold text-sm truncate pr-2">{video.title}</h3>
              <button type="button" onClick={onClose} className="tap-haptic rounded-full p-1 hover:bg-white/10">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            {video.videoId ? (
              <div className="aspect-video">
                <iframe
                  title={video.title}
                  src={`https://www.youtube.com/embed/${video.videoId}?autoplay=1`}
                  className="h-full w-full"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                />
              </div>
            ) : (
              <div className="flex aspect-video items-center justify-center text-slate-400 text-sm">
                No video available — add VITE_YOUTUBE_API_KEY
              </div>
            )}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
