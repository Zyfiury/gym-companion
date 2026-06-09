import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDownIcon, FireIcon, PlayIcon } from '@heroicons/react/24/solid'
import { getExerciseVideo, getCachedVideo, hasYouTubeKey } from '../lib/youtubeApi'
import ExerciseVideoModal from './ExerciseVideoModal'
import ShareToFeedButton from './ShareToFeedButton'
import { awardXP } from '../lib/gamification'

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

function ExerciseRow({ exercise, onPlay }) {
  const [video, setVideo] = useState(() => getCachedVideo(exercise))

  useEffect(() => {
    if (!video) {
      getExerciseVideo(exercise).then(setVideo)
    }
  }, [exercise, video])

  return (
    <li className="flex items-center gap-2 rounded-lg bg-white/5 px-3 py-2 text-sm">
      <button
        type="button"
        onClick={() => video && onPlay(video)}
        className="tap-haptic flex shrink-0 items-center gap-2"
        aria-label={`Play video for ${exercise}`}
      >
        {video?.thumbnail ? (
          <img src={video.thumbnail} alt="" className="h-10 w-14 rounded object-cover" />
        ) : (
          <div className="flex h-10 w-14 items-center justify-center rounded bg-violet-500/20">
            <PlayIcon className="h-4 w-4 text-violet-400" />
          </div>
        )}
      </button>
      <span className="flex-1">{exercise}</span>
    </li>
  )
}

export default function WorkoutPlanDisplay({ userData, onUpdate }) {
  const today = DAY_NAMES[new Date().getDay()]
  const workouts = userData.weeklyPlan?.workouts ?? []
  const todayWorkout = workouts.find((w) => w.day === today) ?? workouts[0]
  const [expanded, setExpanded] = useState(today)
  const [modalVideo, setModalVideo] = useState(null)
  const [completed, setCompleted] = useState(false)

  const handleCompleteWorkout = () => {
    const gamification = awardXP(userData, 'workout')
    onUpdate?.({ gamification })
    setCompleted(true)
  }

  return (
    <section className="space-y-4" data-testid="workout-plan">
      {!hasYouTubeKey() && (
        <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs text-amber-300">
          Set VITE_YOUTUBE_API_KEY in .env for exercise demo videos
        </div>
      )}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        className="card-glow overflow-hidden"
      >
        <div className="mb-3 flex items-center gap-2">
          <div className="rounded-lg bg-gradient-to-br from-violet-500 to-blue-500 p-2">
            <FireIcon className="h-5 w-5 text-white" />
          </div>
          <div className="flex-1">
            <h2 className="font-semibold">Today&apos;s workout</h2>
            <p className="text-sm text-slate-400">{today} · {todayWorkout?.focus ?? 'Rest'}</p>
          </div>
        </div>
        <div className="carousel-scroll">
          {(todayWorkout?.exercises ?? ['Rest day']).map((ex, i) => (
            <div key={i} className="min-w-[200px] snap-center rounded-xl border border-violet-500/20 bg-surface-elevated p-3">
              <p className="text-sm font-medium">{ex}</p>
            </div>
          ))}
        </div>

        {todayWorkout?.focus !== 'Rest' && (
          <div className="mt-3 flex items-center gap-2">
            <button
              type="button"
              onClick={handleCompleteWorkout}
              disabled={completed}
              className="btn-gradient tap-haptic flex-1 text-sm"
              data-testid="complete-workout"
            >
              {completed ? '✅ Workout logged (+10 XP)' : 'Complete workout'}
            </button>
            {completed && (
              <ShareToFeedButton
                type="workout"
                content={`Completed ${todayWorkout.focus} workout on ${today}! 💪`}
                userData={userData}
                onUpdate={onUpdate}
              />
            )}
          </div>
        )}
      </motion.div>

      <div className="space-y-2">
        <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">Weekly split</h3>
        {workouts.map((w) => {
          const isOpen = expanded === w.day
          const isToday = w.day === today
          return (
            <div key={w.day} className={`card overflow-hidden transition ${isToday ? 'ring-1 ring-violet-500/40' : ''}`}>
              <button
                type="button"
                onClick={() => setExpanded(isOpen ? null : w.day)}
                className="tap-haptic flex w-full items-center justify-between py-1"
              >
                <span className={`font-medium ${isToday ? 'text-violet-400' : ''}`}>
                  {w.day} — {w.focus}
                </span>
                <motion.span animate={{ rotate: isOpen ? 180 : 0 }}>
                  <ChevronDownIcon className="h-5 w-5 text-slate-500" />
                </motion.span>
              </button>
              <AnimatePresence>
                {isOpen && (
                  <motion.ul
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    className="space-y-1.5 overflow-hidden pt-2"
                  >
                    {w.exercises?.map((ex, i) => (
                      <ExerciseRow key={i} exercise={ex} onPlay={setModalVideo} />
                    ))}
                  </motion.ul>
                )}
              </AnimatePresence>
            </div>
          )
        })}
      </div>

      <ExerciseVideoModal open={!!modalVideo} onClose={() => setModalVideo(null)} video={modalVideo} />
    </section>
  )
}
