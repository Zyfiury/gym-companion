import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { XMarkIcon, MagnifyingGlassIcon } from '@heroicons/react/24/outline'
import { searchFood, scaleMacros, createFoodLogEntry, addToFoodLog } from '../lib/nutritionApi'
import { awardXP } from '../lib/gamification'
import LoadingSpinner from './LoadingSpinner'

export default function FoodSearchModal({ open, onClose, userData, onUpdate, initialQuery = '' }) {
  const [query, setQuery] = useState(initialQuery)
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [grams, setGrams] = useState(100)
  const [selected, setSelected] = useState(null)

  useEffect(() => {
    if (open && initialQuery) {
      setQuery(initialQuery)
      doSearch(initialQuery)
    }
  }, [open, initialQuery])

  const doSearch = async (q) => {
    if (!q.trim()) return
    setLoading(true)
    setResults(await searchFood(q))
    setLoading(false)
  }

  const logFood = (food) => {
    const macros = scaleMacros(food.per100g, grams)
    const entry = createFoodLogEntry(food, grams, macros)
    const { foodLog, dailyMacrosLogged } = addToFoodLog(userData, entry)
    const gamification = awardXP({ ...userData, foodLog }, 'meal')
    onUpdate({ foodLog, dailyMacrosLogged, gamification })
    onClose()
  }

  return (
    <AnimatePresence>
      {open && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-4 sm:items-center" onClick={onClose}>
          <motion.div initial={{ y: 40, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 40, opacity: 0 }}
            className="w-full max-w-lg rounded-2xl bg-surface-card p-4 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <div className="mb-4 flex items-center justify-between">
              <h3 className="font-semibold">Search for a food</h3>
              <button type="button" onClick={onClose} className="tap-haptic rounded-full p-1 hover:bg-white/10"><XMarkIcon className="h-5 w-5" /></button>
            </div>
            <div className="mb-3 flex gap-2">
              <div className="relative flex-1">
                <MagnifyingGlassIcon className="absolute left-3 top-3 h-4 w-4 text-slate-500" />
                <input value={query} onChange={(e) => setQuery(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && doSearch(query)}
                  placeholder="e.g. chicken breast" className="input-field pl-9" autoFocus />
              </div>
              <button type="button" onClick={() => doSearch(query)} className="btn-gradient tap-haptic shrink-0">Search</button>
            </div>
            <div className="mb-3 flex items-center gap-2">
              <label className="text-sm text-slate-400">Amount (g):</label>
              <input type="number" value={grams} onChange={(e) => setGrams(Number(e.target.value))} className="input-field w-24" min={1} />
            </div>
            {loading ? (
              <div className="flex justify-center py-8"><LoadingSpinner /></div>
            ) : (
              <div className="max-h-64 space-y-2 overflow-y-auto">
                {results.length === 0 && query && <p className="py-4 text-center text-sm text-slate-500">No results found</p>}
                {results.map((food, i) => (
                  <button key={i} type="button" onClick={() => logFood(food)}
                    className="tap-haptic w-full rounded-xl border border-white/5 bg-white/5 p-3 text-left transition hover:border-violet-500/30 hover:bg-violet-500/10">
                    <p className="font-medium text-sm">{food.name}</p>
                    <p className="text-xs text-slate-400">
                      per 100g: {Math.round(food.per100g.calories)} kcal · P {food.per100g.protein}g
                      {grams !== 100 && ` → ${Math.round(food.per100g.calories * grams / 100)} kcal for ${grams}g`}
                    </p>
                  </button>
                ))}
              </div>
            )}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
