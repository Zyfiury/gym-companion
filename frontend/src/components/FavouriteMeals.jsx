import { useState } from 'react'
import { motion } from 'framer-motion'
import { HeartIcon, XMarkIcon } from '@heroicons/react/24/outline'

export default function FavouriteMeals({ userData, onUpdate }) {
  const favourites = userData.favouriteMeals ?? []
  const [name, setName] = useState('')

  return (
    <section className="card" data-testid="favourite-meals">
      <div className="mb-3 flex items-center gap-2">
        <HeartIcon className="h-5 w-5 text-violet-400" />
        <h2 className="font-semibold">Favourites</h2>
      </div>
      <div className="mb-3 flex gap-2">
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Meal name" className="input-field" data-testid="fav-input" />
        <button type="button" onClick={() => { if (name.trim()) { onUpdate({ favouriteMeals: [...favourites, { name: name.trim(), savedAt: Date.now() }] }); setName('') } }} className="btn-gradient tap-haptic shrink-0" data-testid="save-fav">Save</button>
      </div>
      <ul className="space-y-2">
        {favourites.length === 0 && <li className="text-sm text-slate-500">No favourites yet.</li>}
        {favourites.map((m, i) => (
          <motion.li key={i} layout className="flex items-center justify-between rounded-xl bg-white/5 px-3 py-2 text-sm">
            <span>{m.name}</span>
            <button type="button" onClick={() => onUpdate({ favouriteMeals: favourites.filter((_, j) => j !== i) })} className="tap-haptic text-slate-500 hover:text-red-400">
              <XMarkIcon className="h-4 w-4" />
            </button>
          </motion.li>
        ))}
      </ul>
    </section>
  )
}
