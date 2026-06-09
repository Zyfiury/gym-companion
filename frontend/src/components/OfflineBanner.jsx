import { motion, AnimatePresence } from 'framer-motion'
import { SignalSlashIcon } from '@heroicons/react/24/outline'

export default function OfflineBanner({ online }) {
  return (
    <AnimatePresence>
      {!online && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: 'auto', opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          className="overflow-hidden"
        >
          <div className="flex items-center justify-center gap-2 bg-amber-500/20 px-4 py-2 text-sm text-amber-300" data-testid="offline-banner">
            <SignalSlashIcon className="h-4 w-4" />
            Offline — messages queued, will sync when back online
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
