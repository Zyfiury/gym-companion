import { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'
import { QrCodeIcon, CameraIcon } from '@heroicons/react/24/outline'
import { lookupBarcode, scaleMacros, createFoodLogEntry, addToFoodLog } from '../lib/nutritionApi'
import { awardXP } from '../lib/gamification'
import ShareToFeedButton from './ShareToFeedButton'

export default function BarcodeScanner({ userData, onUpdate }) {
  const [scanning, setScanning] = useState(false)
  const [lastScan, setLastScan] = useState(null)
  const [pendingFood, setPendingFood] = useState(null)
  const [manualCode, setManualCode] = useState('')
  const [loading, setLoading] = useState(false)
  const videoRef = useRef(null)
  const streamRef = useRef(null)

  const targets = userData.weeklyPlan?.macros ?? { calories: 2200, protein: 140, carbs: 220, fat: 65 }
  const logged = userData.dailyMacrosLogged ?? { calories: 0, protein: 0, carbs: 0, fat: 0 }

  const logFood = (food, grams = 100) => {
    const macros = scaleMacros(food.per100g, grams)
    const entry = createFoodLogEntry(food, grams, macros)
    const { foodLog, dailyMacrosLogged } = addToFoodLog(userData, entry)
    const gamification = awardXP({ ...userData, foodLog }, 'barcode')
    onUpdate({ foodLog, dailyMacrosLogged, gamification })
    setLastScan({ ...food, ...macros, grams, onTrack: dailyMacrosLogged.calories <= targets.calories })
    setPendingFood(null)
  }

  const handleScan = async (code) => {
    if (!code) return
    setLoading(true)
    const food = await lookupBarcode(code)
    setLoading(false)
    if (!food) {
      setLastScan({ name: 'Product not found', error: true })
      return
    }
    setPendingFood(food)
    stopCamera()
  }

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        await videoRef.current.play()
      }
      setScanning(true)
    } catch {
      alert('Camera access denied. Enter barcode manually.')
    }
  }

  const stopCamera = () => {
    streamRef.current?.getTracks().forEach((t) => t.stop())
    streamRef.current = null
    setScanning(false)
  }

  useEffect(() => () => stopCamera(), [])

  const pct = Math.min(100, Math.round((logged.calories / targets.calories) * 100))

  return (
    <section className="card" data-testid="barcode-scanner">
      <div className="mb-3 flex items-center gap-2">
        <QrCodeIcon className="h-5 w-5 text-violet-400" />
        <h2 className="font-semibold">Log food</h2>
        <span className="ml-auto text-xs text-slate-500">Open Food Facts</span>
      </div>
      <div className="mb-3">
        <div className="mb-1 flex justify-between text-sm">
          <span className="text-slate-400">Calories</span>
          <span>{logged.calories} / {targets.calories}</span>
        </div>
        <div className="h-2 overflow-hidden rounded-full bg-white/10">
          <motion.div
            className={`h-full rounded-full ${pct > 100 ? 'bg-amber-500' : 'bg-gradient-brand'}`}
            animate={{ width: `${Math.min(pct, 100)}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>

      {scanning ? (
        <div className="relative mb-3 aspect-video overflow-hidden rounded-xl ring-2 ring-violet-500/50">
          <video ref={videoRef} className="h-full w-full object-cover" playsInline muted />
          <button type="button" onClick={stopCamera} className="absolute right-2 top-2 rounded-lg bg-black/70 px-2 py-1 text-xs">Stop</button>
        </div>
      ) : (
        <button type="button" onClick={startCamera} className="btn-ghost tap-haptic mb-3 flex w-full items-center justify-center gap-2" data-testid="start-camera">
          <CameraIcon className="h-5 w-5" /> Open camera
        </button>
      )}

      <div className="flex gap-2">
        <input type="text" value={manualCode} onChange={(e) => setManualCode(e.target.value)} placeholder="Barcode…" className="input-field flex-1" data-testid="barcode-input" />
        <button type="button" onClick={() => handleScan(manualCode)} disabled={loading} className="btn-gradient tap-haptic shrink-0" data-testid="scan-submit">
          {loading ? '…' : 'Scan'}
        </button>
      </div>

      {pendingFood && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="mt-3 rounded-xl border border-violet-500/30 bg-violet-500/10 p-3" data-testid="scan-result">
          {pendingFood.image && <img src={pendingFood.image} alt="" className="mb-2 h-16 rounded-lg object-cover" />}
          <p className="font-medium">{pendingFood.name}</p>
          {pendingFood.brand && <p className="text-xs text-slate-400">{pendingFood.brand}</p>}
          <p className="mt-1 text-sm text-slate-300">
            per 100g: {Math.round(pendingFood.per100g.calories)} kcal · P {pendingFood.per100g.protein}g
          </p>
          <button type="button" onClick={() => logFood(pendingFood, 100)} className="btn-gradient tap-haptic mt-2 w-full text-sm" data-testid="log-food-tap">
            Log 100g (+5 XP)
          </button>
        </motion.div>
      )}

      {lastScan && !pendingFood && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className={`mt-3 rounded-xl p-3 text-sm ${lastScan.error ? 'bg-red-500/10 text-red-300' : lastScan.onTrack ? 'bg-violet-500/10 text-violet-300' : 'bg-amber-500/10 text-amber-300'}`}>
          {lastScan.error ? (
            <p>Product not found in Open Food Facts.</p>
          ) : (
            <>
              <p className="font-medium">{lastScan.name} logged</p>
              <p>+{lastScan.calories} kcal · P {lastScan.protein}g</p>
              <ShareToFeedButton type="meal" content={`Logged ${lastScan.name} — ${lastScan.calories} kcal`} userData={userData} onUpdate={onUpdate} />
            </>
          )}
        </motion.div>
      )}
    </section>
  )
}
