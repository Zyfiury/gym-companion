import { motion } from 'framer-motion'
import { WalletIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline'

export default function BudgetTracker({ userData, onUpdate }) {
  const budget = userData.weeklyBudget ?? 50
  const spent = userData.budgetSpent ?? 0
  const pct = Math.round((spent / budget) * 100)
  const over = spent > budget

  return (
    <section className="card" data-testid="budget-tracker">
      <div className="mb-3 flex items-center gap-2">
        <WalletIcon className="h-5 w-5 text-violet-400" />
        <h2 className="font-semibold">Food budget</h2>
      </div>
      <div className="mb-2 flex justify-between text-sm">
        <span className="text-slate-400">This week</span>
        <span className={over ? 'text-amber-400' : 'text-violet-400'}>£{spent.toFixed(2)} / £{budget}</span>
      </div>
      <div className="mb-3 h-2 overflow-hidden rounded-full bg-white/10">
        <motion.div className={`h-full rounded-full ${over ? 'bg-amber-500' : 'bg-gradient-brand'}`} animate={{ width: `${Math.min(pct, 100)}%` }} />
      </div>
      {over && (
        <p className="mb-3 flex items-center gap-1 text-sm text-amber-400" data-testid="budget-warning">
          <ExclamationTriangleIcon className="h-4 w-4" /> Over budget — swap a meal for home cooking.
        </p>
      )}
      <div className="flex gap-2">
        {[5, 10, 15].map((n) => (
          <button key={n} type="button" onClick={() => onUpdate({ budgetSpent: spent + n })} className="btn-ghost tap-haptic flex-1 text-sm">+£{n}</button>
        ))}
      </div>
    </section>
  )
}
