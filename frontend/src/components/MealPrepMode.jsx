import { motion } from 'framer-motion'
import { CalendarDaysIcon, PlayCircleIcon } from '@heroicons/react/24/outline'
import { sendSessionMessage } from '../lib/sessions'

export default function MealPrepMode({ userData }) {
  const shopping = userData.weeklyPlan?.shoppingList
  const batchVideoId = userData.weeklyPlan?.meals?.[0]?.youtubeVideoId

  return (
    <section className="card-glow" data-testid="meal-prep">
      <div className="mb-2 flex items-center gap-2">
        <CalendarDaysIcon className="h-5 w-5 text-violet-400" />
        <h2 className="font-semibold">Meal prep mode</h2>
      </div>
      <p className="mb-3 text-sm text-slate-400">Batch cook for the week · £{userData.weeklyBudget ?? 50} budget</p>
      <button type="button" onClick={() => sendSessionMessage('MEAL_PREP_WEEK: generate full shopping list and batch cooking plan')} className="btn-gradient tap-haptic mb-4 w-full" data-testid="generate-prep">
        Generate week prep
      </button>
      {shopping && (
        <ul className="mb-4 space-y-1 text-sm text-slate-300">
          {shopping.items?.map((item, i) => (
            <li key={i}>• {item.item} — {item.price}</li>
          ))}
        </ul>
      )}
      {batchVideoId && (
        <div>
          <p className="mb-2 flex items-center gap-1 text-xs text-slate-400"><PlayCircleIcon className="h-4 w-4" /> Batch guide</p>
          <div className="aspect-video overflow-hidden rounded-xl ring-1 ring-violet-500/30">
            <iframe title="Batch cooking" className="h-full w-full" src={`https://www.youtube.com/embed/${batchVideoId}`} allowFullScreen />
          </div>
        </div>
      )}
    </section>
  )
}
