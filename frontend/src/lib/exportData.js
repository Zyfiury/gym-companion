/**
 * Export user data as CSV and PDF.
 */

import Papa from 'papaparse'
import jsPDF from 'jspdf'
import 'jspdf-autotable'
import { getAchievementDetails, calcLevel } from './gamification'
import { generateLocalInsights } from './insights'

function downloadBlob(content, filename, mime) {
  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

export function exportCSV(userData) {
  const date = new Date().toISOString().slice(0, 10)

  const foodLog = userData.foodLog || []
  if (foodLog.length) {
    downloadBlob(Papa.unparse(foodLog), `food-log-${date}.csv`, 'text/csv')
  }

  const progress = userData.weeklyProgressLog || userData.weightHistory || []
  if (progress.length) {
    downloadBlob(Papa.unparse(progress), `progress-log-${date}.csv`, 'text/csv')
  }

  const workouts = (userData.weeklyPlan?.workouts || []).flatMap((w) =>
    (w.exercises || []).map((ex) => ({ day: w.day, focus: w.focus, exercise: ex }))
  )
  if (workouts.length) {
    downloadBlob(Papa.unparse(workouts), `workout-plan-${date}.csv`, 'text/csv')
  }
}

export function exportPDF(userData) {
  const doc = new jsPDF()
  const g = userData.gamification || {}
  const achievements = getAchievementDetails(g).filter((a) => a.earned)
  const insights = userData.recentInsights?.slice(0, 4).map((i) => i.text) || generateLocalInsights(userData).slice(0, 4)

  doc.setFontSize(18)
  doc.text('Gym Companion Report', 14, 20)
  doc.setFontSize(11)
  doc.text(`Generated: ${new Date().toLocaleDateString()}`, 14, 28)

  doc.setFontSize(14)
  doc.text('Profile Summary', 14, 40)
  doc.setFontSize(10)
  doc.text(`Goal: ${userData.goal || '—'} | Weight: ${userData.weight}kg | TDEE: ${userData.tdee} kcal`, 14, 48)

  doc.setFontSize(14)
  doc.text('Gamification', 14, 60)
  doc.setFontSize(10)
  const level = calcLevel(g.xp ?? 0)
  doc.text(`XP: ${g.xp ?? 0} | Level: ${level} | Streak: ${g.streak ?? 0} days`, 14, 68)

  if (achievements.length) {
    doc.autoTable({
      startY: 74,
      head: [['Achievement', 'Status']],
      body: achievements.map((a) => [a.name, '✓ Earned']),
      theme: 'striped',
      headStyles: { fillColor: [139, 92, 246] },
    })
  }

  let y = doc.lastAutoTable?.finalY ?? 80
  y += 10
  doc.setFontSize(14)
  doc.text('Recent Insights', 14, y)
  y += 8
  doc.setFontSize(9)
  insights.slice(0, 4).forEach((ins) => {
    const lines = doc.splitTextToSize(`• ${ins}`, 180)
    doc.text(lines, 14, y)
    y += lines.length * 5 + 2
  })

  const foodLog = userData.foodLog || []
  if (foodLog.length) {
    y += 6
    doc.setFontSize(14)
    doc.text('Food Log (recent)', 14, y)
    doc.autoTable({
      startY: y + 4,
      head: [['Date', 'Food', 'Amount', 'Cal', 'P', 'C', 'F']],
      body: foodLog.slice(-10).map((f) => [f.date, f.food, f.amount, f.calories, f.protein, f.carbs, f.fat]),
      theme: 'striped',
      headStyles: { fillColor: [139, 92, 246] },
    })
  }

  doc.save(`gym-report-${new Date().toISOString().slice(0, 10)}.pdf`)
}
