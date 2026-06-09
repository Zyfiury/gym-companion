import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  UserIcon,
  ScaleIcon,
  CurrencyPoundIcon,
  CakeIcon,
  FlagIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  CheckIcon,
} from '@heroicons/react/24/outline'
import { ArrowDownTrayIcon } from '@heroicons/react/24/outline'
import { sendSessionMessage } from '../lib/sessions'
import { exportCSV, exportPDF } from '../lib/exportData'

const STEPS = [
  { id: 'goal', title: 'Your goal', icon: FlagIcon, fields: ['goal'] },
  { id: 'body', title: 'Body stats', icon: ScaleIcon, fields: ['weight', 'height', 'age'] },
  { id: 'nutrition', title: 'Nutrition', icon: CakeIcon, fields: ['tdee', 'weeklyBudget', 'nutritionMode', 'dietaryRestrictions'] },
]

export default function UserProfileForm({ userData, onUpdate }) {
  const [step, setStep] = useState(0)
  const [form, setForm] = useState({
    goal: userData.goal || '',
    weight: userData.weight ?? 70,
    height: userData.height ?? 175,
    age: userData.age ?? 30,
    tdee: userData.tdee ?? 2200,
    weeklyBudget: userData.weeklyBudget ?? 50,
    nutritionMode: userData.nutritionMode || 'cook_myself',
    dietaryRestrictions: userData.dietaryRestrictions || 'none',
  })
  const [saved, setSaved] = useState(false)

  const handleChange = (e) => {
    const { name, value, type } = e.target
    setForm((f) => ({ ...f, [name]: type === 'number' ? Number(value) : value }))
    setSaved(false)
  }

  const handleSave = async () => {
    await sendSessionMessage(`USER_PROFILE_UPDATE: ${JSON.stringify(form)}`)
    onUpdate(form)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const current = STEPS[step]
  const Icon = current.icon
  const progress = ((step + 1) / STEPS.length) * 100

  return (
    <section className="card-glow" data-testid="profile-form">
      <div className="mb-4 flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-brand">
          <UserIcon className="h-5 w-5 text-white" />
        </div>
        <div className="flex-1">
          <h2 className="font-semibold">Profile setup</h2>
          <p className="text-xs text-slate-400">Step {step + 1} of {STEPS.length}</p>
        </div>
      </div>

      <div className="mb-4 h-1.5 overflow-hidden rounded-full bg-white/10">
        <motion.div className="h-full bg-gradient-brand" animate={{ width: `${progress}%` }} transition={{ duration: 0.3 }} />
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={step}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
          className="space-y-3"
        >
          <div className="mb-2 flex items-center gap-2 text-violet-400">
            <Icon className="h-5 w-5" />
            <span className="font-medium">{current.title}</span>
          </div>

          {step === 0 && (
            <div className="grid grid-cols-3 gap-2">
              {['cut', 'bulk', 'maintain'].map((g) => (
                <button
                  key={g}
                  type="button"
                  onClick={() => setForm((f) => ({ ...f, goal: g }))}
                  className={`tap-haptic rounded-xl border py-3 text-sm font-medium capitalize transition ${
                    form.goal === g
                      ? 'border-violet-500 bg-violet-500/20 text-violet-300'
                      : 'border-white/10 bg-white/5 hover:border-violet-500/30'
                  }`}
                >
                  {g}
                </button>
              ))}
            </div>
          )}

          {step === 1 && (
            <>
              <label className="block">
                <span className="mb-1 block text-xs text-slate-400">Weight (kg)</span>
                <input type="number" name="weight" value={form.weight} onChange={handleChange} className="input-field" />
              </label>
              <div className="grid grid-cols-2 gap-3">
                <label>
                  <span className="mb-1 block text-xs text-slate-400">Height (cm)</span>
                  <input type="number" name="height" value={form.height} onChange={handleChange} className="input-field" />
                </label>
                <label>
                  <span className="mb-1 block text-xs text-slate-400">Age</span>
                  <input type="number" name="age" value={form.age} onChange={handleChange} className="input-field" />
                </label>
              </div>
            </>
          )}

          {step === 2 && (
            <>
              <label>
                <span className="mb-1 block text-xs text-slate-400">TDEE (kcal)</span>
                <input type="number" name="tdee" value={form.tdee} onChange={handleChange} className="input-field" />
              </label>
              <label>
                <span className="mb-1 flex items-center gap-1 text-xs text-slate-400">
                  <CurrencyPoundIcon className="h-3 w-3" /> Weekly budget
                </span>
                <input type="number" name="weeklyBudget" value={form.weeklyBudget} onChange={handleChange} className="input-field" />
              </label>
              <label>
                <span className="mb-1 block text-xs text-slate-400">Nutrition mode</span>
                <select name="nutritionMode" value={form.nutritionMode} onChange={handleChange} className="input-field">
                  <option value="cook_myself">Cook myself</option>
                  <option value="home_delivery">Home delivery</option>
                  <option value="eat_out">Eat out</option>
                </select>
              </label>
              <label>
                <span className="mb-1 block text-xs text-slate-400">Dietary restrictions</span>
                <input type="text" name="dietaryRestrictions" value={form.dietaryRestrictions} onChange={handleChange} className="input-field" />
              </label>
            </>
          )}
        </motion.div>
      </AnimatePresence>

      <div className="mb-4 flex gap-2 border-b border-white/5 pb-4">
        <button type="button" onClick={() => exportCSV(userData)} className="btn-ghost tap-haptic flex flex-1 items-center justify-center gap-1.5 text-sm" data-testid="export-csv">
          <ArrowDownTrayIcon className="h-4 w-4" /> CSV
        </button>
        <button type="button" onClick={() => exportPDF(userData)} className="btn-ghost tap-haptic flex flex-1 items-center justify-center gap-1.5 text-sm" data-testid="export-pdf">
          <ArrowDownTrayIcon className="h-4 w-4" /> PDF
        </button>
      </div>

      <div className="mt-4 flex gap-2">
        {step > 0 && (
          <button type="button" onClick={() => setStep((s) => s - 1)} className="btn-ghost flex items-center gap-1">
            <ChevronLeftIcon className="h-4 w-4" /> Back
          </button>
        )}
        {step < STEPS.length - 1 ? (
          <button type="button" onClick={() => setStep((s) => s + 1)} className="btn-gradient ml-auto flex items-center gap-1">
            Next <ChevronRightIcon className="h-4 w-4" />
          </button>
        ) : (
          <button type="button" onClick={handleSave} className="btn-gradient ml-auto flex items-center gap-1" data-testid="save-profile">
            {saved ? <><CheckIcon className="h-4 w-4" /> Saved</> : 'Save profile'}
          </button>
        )}
      </div>
    </section>
  )
}
