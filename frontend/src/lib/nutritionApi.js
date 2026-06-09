/**
 * Open Food Facts API — free, no key required.
 */

export function scaleMacros(per100g, grams) {
  const factor = grams / 100
  return {
    calories: Math.round((per100g.calories || 0) * factor),
    protein: Math.round((per100g.protein || 0) * factor * 10) / 10,
    carbs: Math.round((per100g.carbs || 0) * factor * 10) / 10,
    fat: Math.round((per100g.fat || 0) * factor * 10) / 10,
  }
}

function parseProduct(p) {
  const n = p.nutriments || {}
  return {
    name: p.product_name || p.generic_name || 'Unknown food',
    per100g: {
      calories: n['energy-kcal_100g'] ?? n['energy-kcal'] ?? 0,
      protein: n.proteins_100g ?? n.proteins ?? 0,
      carbs: n.carbohydrates_100g ?? n.carbohydrates ?? 0,
      fat: n.fat_100g ?? n.fat ?? 0,
    },
    barcode: p.code || p._id,
    brand: p.brands || '',
    image: p.image_front_small_url || p.image_url || null,
  }
}

export async function searchFood(query) {
  try {
    const url = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(query)}&json=1&page_size=5&fields=product_name,generic_name,nutriments,code,brands,image_front_small_url`
    const res = await fetch(url)
    if (!res.ok) return []
    const data = await res.json()
    return (data.products || []).map(parseProduct).filter((p) => p.per100g.calories > 0 || p.per100g.protein > 0)
  } catch {
    return []
  }
}

export async function lookupBarcode(barcode) {
  try {
    const code = String(barcode).trim()
    const res = await fetch(`https://world.openfoodfacts.org/api/v2/product/${code}.json?fields=product_name,generic_name,nutriments,code,brands,image_front_small_url`)
    if (!res.ok) return null
    const data = await res.json()
    if (data.status !== 1 || !data.product) return null
    return parseProduct(data.product)
  } catch {
    return null
  }
}

export function createFoodLogEntry(food, grams, macros) {
  return {
    date: new Date().toISOString().slice(0, 10),
    time: new Date().toISOString(),
    food: food.name,
    amount: `${grams}g`,
    grams,
    calories: macros.calories,
    protein: macros.protein,
    carbs: macros.carbs,
    fat: macros.fat,
    barcode: food.barcode || null,
  }
}

export function addToFoodLog(userData, entry) {
  const foodLog = [...(userData.foodLog || []), entry]
  const logged = userData.dailyMacrosLogged || { calories: 0, protein: 0, carbs: 0, fat: 0 }
  const today = new Date().toISOString().slice(0, 10)
  const isToday = entry.date === today
  const dailyMacrosLogged = isToday
    ? {
        calories: logged.calories + entry.calories,
        protein: logged.protein + entry.protein,
        carbs: logged.carbs + entry.carbs,
        fat: logged.fat + entry.fat,
      }
    : logged
  return { foodLog, dailyMacrosLogged }
}
