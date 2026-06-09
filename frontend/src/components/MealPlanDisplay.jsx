import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDownIcon, ShoppingBagIcon } from '@heroicons/react/24/solid'

export default function MealPlanDisplay({ userData }) {
  const meals = userData.weeklyPlan?.meals ?? []
  const shopping = userData.weeklyPlan?.shoppingList
  const macros = userData.weeklyPlan?.macros ?? {}
  const [openMeal, setOpenMeal] = useState(0)
  const [shopOpen, setShopOpen] = useState(false)

  return (
    <section className="space-y-4" data-testid="meal-plan">
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="card-glow">
        <h2 className="mb-3 font-semibold">Daily macros</h2>
        <div className="grid grid-cols-4 gap-2">
          {[
            { label: 'Cal', val: macros.calories, accent: true },
            { label: 'P', val: `${macros.protein ?? '—'}g` },
            { label: 'C', val: `${macros.carbs ?? '—'}g` },
            { label: 'F', val: `${macros.fat ?? '—'}g` },
          ].map((m) => (
            <div key={m.label} className="rounded-xl bg-surface-elevated p-2 text-center">
              <p className="text-[10px] text-slate-500">{m.label}</p>
              <p className={`font-bold ${m.accent ? 'bg-gradient-brand bg-clip-text text-transparent' : ''}`}>{m.val ?? '—'}</p>
            </div>
          ))}
        </div>
      </motion.div>

      <div className="carousel-scroll" data-testid="meal-carousel">
        {meals.map((meal, i) => (
          <motion.div
            key={i}
            whileTap={{ scale: 0.98 }}
            onClick={() => setOpenMeal(openMeal === i ? -1 : i)}
            className={`min-w-[280px] snap-center cursor-pointer rounded-2xl border p-4 transition ${
              openMeal === i ? 'border-violet-500/50 bg-gradient-card' : 'border-white/10 bg-surface-card'
            }`}
            data-testid={`meal-${i}`}
          >
            <p className="text-[10px] uppercase tracking-wider text-violet-400">{meal.mealType}</p>
            <h3 className="font-semibold">{meal.name}</h3>
            <p className="text-sm text-slate-400">{meal.description}</p>
            <AnimatePresence>
              {openMeal === i && (
                <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} className="overflow-hidden">
                  {meal.steps?.length > 0 && (
                    <ol className="mt-2 list-decimal space-y-1 pl-4 text-sm text-slate-300">
                      {meal.steps.map((s, j) => (
                        <li key={j}>{s}</li>
                      ))}
                    </ol>
                  )}
                  {meal.youtubeVideoId && (
                    <div className="mt-3 aspect-video overflow-hidden rounded-xl">
                      <iframe
                        title={meal.name}
                        className="h-full w-full"
                        src={`https://www.youtube.com/embed/${meal.youtubeVideoId}`}
                        allowFullScreen
                      />
                    </div>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        ))}
      </div>

      {shopping && (
        <div className="card" data-testid="shopping-list">
          <button type="button" onClick={() => setShopOpen(!shopOpen)} className="tap-haptic flex w-full items-center justify-between">
            <div className="flex items-center gap-2">
              <ShoppingBagIcon className="h-5 w-5 text-violet-400" />
              <span className="font-semibold">{shopping.supermarket}</span>
            </div>
            <span className="text-sm text-violet-400">{shopping.totalEstimatedCost}</span>
          </button>
          <AnimatePresence>
            {shopOpen && (
              <motion.ul initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="mt-3 space-y-1 text-sm">
                {shopping.items?.map((item, i) => (
                  <li key={i} className="flex justify-between text-slate-300">
                    <span>{item.item} × {item.quantity}</span>
                    <span>{item.price}</span>
                  </li>
                ))}
              </motion.ul>
            )}
          </AnimatePresence>
        </div>
      )}
    </section>
  )
}
