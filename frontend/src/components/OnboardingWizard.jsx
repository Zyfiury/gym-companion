import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { FlagIcon, ScaleIcon, CakeIcon, ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline'
import { useAuth } from '../context/AuthContext'
import LoadingSpinner from './LoadingSpinner'

const STEPS = [
  { id: 'goal', title: 'Your goal', icon: FlagIcon },
  { id: 'body', title: 'Body stats', icon: ScaleIcon },
  { id: 'nutrition', title: 'Nutrition', icon: CakeIcon },
]

export default function OnboardingWizard() {
  const { userData, completeOnboarding } = useAuth()
  const [step, setStep] = useState(0)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    goal: '',
    weight: 70,
    height: 175,
    age: 30,
    tdee: 2200,
    weeklyBudget: 50,
    nutritionMode: 'cook_myself',
    dietaryRestrictions: 'none',
  })

  const handleSave = async () => {
    setSaving(true)
    let tdee = form.tdee
    if (form.goal === 'cut') tdee = Math.round(tdee - 500)
    else if (form.goal === 'bulk') tdee = Math.round(tdee + 300)
    await completeOnboarding({ ...form, tdee, weeklyPlan: { ...userData?.weeklyPlan, macros: { calories: tdee, protein: 140, carbs: 220, fat: 65 } } })
    setSaving(false)
  }

  const current = STEPS[step]
  const Icon = current.icon

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-surface p-4">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md card-glow">
        <h2 className="mb-1 text-xl font-bold">Welcome! Let&apos;s set up your profile</h2>
        <p className="mb-4 text-sm text-slate-400">Step {step + 1} of {STEPS.length}</p>

        <div className="mb-4 h-1.5 overflow-hidden rounded-full bg-white/10">
          <motion.div className="h-full bg-gradient-brand" animate={{ width: `${((step + 1) / STEPS.length) * 100}%` }} />
        </div>

        <AnimatePresence mode="wait">
          <motion.div key={step} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} className="space-y-3">
            <div className="mb-2 flex items-center gap-2 text-violet-400">
              <Icon className="h-5 w-5" />
              <span className="font-medium">{current.title}</span>
            </div>

            {step === 0 && (
              <div className="grid grid-cols-3 gap-2">
                {['cut', 'bulk', 'maintain'].map((g) => (
                  <button key={g} type="button" onClick={() => setForm((f) => ({ ...f, goal: g }))}
                    className={`tap-haptic rounded-xl border py-3 text-sm font-medium capitalize ${form.goal === g ? 'border-violet-500 bg-violet-500/20 text-violet-300' : 'border-white/10 bg-white/5'}`}>
                    {g}
                  </button>
                ))}
              </div>
            )}
            {step === 1 && (
              <>
                <label className="block"><span className="mb-1 block text-xs text-slate-400">Weight (kg)</span>
                  <input type="number" value={form.weight} onChange={(e) => setForm((f) => ({ ...f, weight: Number(e.target.value) }))} className="input-field" /></label>
                <div className="grid grid-cols-2 gap-3">
                  <label><span className="mb-1 block text-xs text-slate-400">Height (cm)</span>
                    <input type="number" value={form.height} onChange={(e) => setForm((f) => ({ ...f, height: Number(e.target.value) }))} className="input-field" /></label>
                  <label><span className="mb-1 block text-xs text-slate-400">Age</span>
                    <input type="number" value={form.age} onChange={(e) => setForm((f) => ({ ...f, age: Number(e.target.value) }))} className="input-field" /></label>
                </div>
              </>
            )}
            {step === 2 && (
              <>
                <label><span className="mb-1 block text-xs text-slate-400">TDEE (kcal)</span>
                  <input type="number" value={form.tdee} onChange={(e) => setForm((f) => ({ ...f, tdee: Number(e.target.value) }))} className="input-field" /></label>
                <label><span className="mb-1 block text-xs text-slate-400">Weekly budget (£)</span>
                  <input type="number" value={form.weeklyBudget} onChange={(e) => setForm((f) => ({ ...f, weeklyBudget: Number(e.target.value) }))} className="input-field" /></label>
                <select value={form.nutritionMode} onChange={(e) => setForm((f) => ({ ...f, nutritionMode: e.target.value }))} className="input-field">
                  <option value="cook_myself">Cook myself</option>
                  <option value="home_delivery">Home delivery</option>
                  <option value="eat_out">Eat out</option>
                </select>
              </>
            )}
          </motion.div>
        </AnimatePresence>

        <div className="mt-6 flex gap-2">
          {step > 0 && <button type="button" onClick={() => setStep((s) => s - 1)} className="btn-ghost flex items-center gap-1"><ChevronLeftIcon className="h-4 w-4" /> Back</button>}
          {step < STEPS.length - 1 ? (
            <button type="button" onClick={() => setStep((s) => s + 1)} disabled={step === 0 && !form.goal} className="btn-gradient ml-auto flex items-center gap-1">
              Next <ChevronRightIcon className="h-4 w-4" />
            </button>
          ) : (
            <button type="button" onClick={handleSave} disabled={saving} className="btn-gradient ml-auto">
              {saving ? <LoadingSpinner size="sm" /> : 'Start training'}
            </button>
          )}
        </div>
      </motion.div>
    </div>
  )
}
