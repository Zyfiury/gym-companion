/**
 * YouTube Data API — exercise demo videos with localStorage cache.
 */

const CACHE_KEY = 'gymapp_exercise_video_cache'
const PLACEHOLDER = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="120" height="68" fill="%238b5cf6"><rect width="120" height="68" rx="8" fill="%231a1a2e"/><text x="60" y="38" text-anchor="middle" fill="%238b5cf6" font-size="24">▶</text></svg>')

function loadCache() {
  try { return JSON.parse(localStorage.getItem(CACHE_KEY) || '{}') } catch { return {} }
}

function saveCache(cache) {
  localStorage.setItem(CACHE_KEY, JSON.stringify(cache))
}

export function parseExerciseName(exerciseStr) {
  return exerciseStr.replace(/\s+\d+.*$/, '').trim()
}

export function hasYouTubeKey() {
  return !!import.meta.env.VITE_YOUTUBE_API_KEY
}

export async function getExerciseVideo(exerciseName) {
  const key = parseExerciseName(exerciseName).toLowerCase()
  const cache = loadCache()
  if (cache[key]) return { ...cache[key], hasKey: hasYouTubeKey() }

  const apiKey = import.meta.env.VITE_YOUTUBE_API_KEY
  if (!apiKey) {
    return { videoId: null, title: exerciseName, thumbnail: PLACEHOLDER, warning: 'Set VITE_YOUTUBE_API_KEY for exercise videos', hasKey: false }
  }

  try {
    const q = encodeURIComponent(`${parseExerciseName(exerciseName)} exercise form tutorial`)
    const res = await fetch(
      `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${q}&type=video&maxResults=1&videoEmbeddable=true&key=${apiKey}`
    )
    if (!res.ok) throw new Error('API error')
    const data = await res.json()
    const item = data.items?.[0]
    if (!item) return { videoId: null, title: exerciseName, thumbnail: PLACEHOLDER, hasKey: true }

    const result = {
      videoId: item.id.videoId,
      title: item.snippet.title,
      thumbnail: item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url,
      hasKey: true,
    }
    cache[key] = result
    saveCache(cache)
    return result
  } catch {
    return { videoId: null, title: exerciseName, thumbnail: PLACEHOLDER, hasKey: true }
  }
}

export function getCachedVideo(exerciseName) {
  const key = parseExerciseName(exerciseName).toLowerCase()
  return loadCache()[key] || null
}
