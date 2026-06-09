import { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'
import { PaperAirplaneIcon, SparklesIcon, MicrophoneIcon, MagnifyingGlassIcon } from '@heroicons/react/24/solid'
import { loadChatMessages, saveChatMessages } from '../lib/offlineStore'
import { sendChatCommand } from '../lib/sessions'
import { processChatCommand } from '../lib/chatAgent'
import { shouldShowMondayInsight, generateInsightWithGroq } from '../lib/insights'
import { useAuth } from '../context/AuthContext'
import FoodSearchModal from './FoodSearchModal'

function formatMarkdown(text) {
  return text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>').replace(/\n/g, '<br/>')
}

const SpeechRecognition = typeof window !== 'undefined'
  ? (window.SpeechRecognition || window.webkitSpeechRecognition)
  : null

export default function ChatInterface({ embedded = false, userData, onUpdate, onNavigate }) {
  const { userId } = useAuth()
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [typing, setTyping] = useState(false)
  const [listening, setListening] = useState(false)
  const [foodSearchOpen, setFoodSearchOpen] = useState(false)
  const [foodSearchQuery, setFoodSearchQuery] = useState('')
  const bottomRef = useRef(null)
  const inputRef = useRef(null)

  useEffect(() => {
    if (!userId) return
    loadChatMessages(userId).then((h) => {
      setMessages(h.length ? h : [{
        id: 0, role: 'assistant',
        content: "Hi! I'm your AI coach. Ask me to log food, update your profile, show workouts, or get insights.",
        ts: new Date().toISOString(),
      }])
    })
  }, [userId])

  useEffect(() => {
    if (messages.length && userId) saveChatMessages(messages, userId)
  }, [messages, userId])

  useEffect(() => {
    if (shouldShowMondayInsight(userId)) {
      generateInsightWithGroq(userData, messages, userId).then((insight) => {
        const msg = { id: Date.now(), role: 'assistant', content: `📊 **Weekly insight**\n\n${insight}`, ts: new Date().toISOString() }
        setMessages((m) => [...m, msg])
      })
    }
  }, [userId]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
  }, [messages, typing])

  const handleVoiceCommand = (text) => {
    const lower = text.toLowerCase()
    if (/start.*workout|open workout|go to workout/i.test(lower)) { onNavigate?.('workout'); return true }
    if (/log.*breakfast|log.*lunch|log.*dinner|open meals|food log/i.test(lower)) { onNavigate?.('meals'); return true }
    if (/search.*food|find.*food/i.test(lower)) {
      const q = lower.replace(/search.*food|find.*food|for\s+/gi, '').trim()
      setFoodSearchQuery(q || '')
      setFoodSearchOpen(true)
      return true
    }
    if (/show.*progress|open progress/i.test(lower)) { onNavigate?.('progress'); return true }
    if (/open.*feed|show.*feed/i.test(lower)) { onNavigate?.('feed'); return true }
    return false
  }

  const handleSend = async (textOverride) => {
    const text = (textOverride || input).trim()
    if (!text || typing) return

    if (handleVoiceCommand(text)) {
      setMessages((m) => [...m,
        { id: Date.now(), role: 'user', content: text, ts: new Date().toISOString() },
        { id: Date.now() + 1, role: 'assistant', content: 'On it!', ts: new Date().toISOString() },
      ])
      setInput('')
      return
    }

    if (/search.*food|find.*food/i.test(text.toLowerCase())) {
      setFoodSearchQuery(text.replace(/search.*food|find.*food/gi, '').trim())
      setFoodSearchOpen(true)
      return
    }

    const userMsg = { id: Date.now(), role: 'user', content: text, ts: new Date().toISOString() }
    setMessages((m) => [...m, userMsg])
    setInput('')
    setTyping(true)

    await sendChatCommand(text, userData, userId)
    const { patch, reply } = await processChatCommand(text, userData, messages)
    if (Object.keys(patch).length) onUpdate(patch)

    await new Promise((r) => setTimeout(r, 400 + Math.random() * 300))
    setMessages((m) => [...m, { id: Date.now(), role: 'assistant', content: reply, ts: new Date().toISOString() }])
    setTyping(false)
  }

  const startListening = () => {
    if (!SpeechRecognition) { alert('Voice input not supported. Try Chrome.'); return }
    const recognition = new SpeechRecognition()
    recognition.continuous = false
    recognition.interimResults = true
    recognition.lang = 'en-GB'
    recognition.onstart = () => setListening(true)
    recognition.onend = () => setListening(false)
    recognition.onerror = () => setListening(false)
    recognition.onresult = (e) => {
      const transcript = Array.from(e.results).map((r) => r[0].transcript).join('')
      setInput(transcript)
      if (e.results[e.results.length - 1].isFinal) handleSend(transcript)
    }
    recognition.start()
  }

  return (
    <div className={embedded ? 'flex flex-col' : 'fixed inset-0 z-50 flex flex-col bg-surface'} data-testid="chat-interface">
      {embedded && (
        <div className="mb-3 flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-brand">
            <SparklesIcon className="h-5 w-5 text-white" />
          </div>
          <div className="flex-1">
            <h2 className="font-semibold">AI Coach</h2>
            <p className="text-xs text-slate-400">Powered by Groq · your main interface</p>
          </div>
          <button type="button" onClick={() => setFoodSearchOpen(true)} className="btn-ghost tap-haptic flex items-center gap-1 text-xs" data-testid="food-search-btn">
            <MagnifyingGlassIcon className="h-4 w-4" /> Food
          </button>
        </div>
      )}

      <div className={`flex-1 overflow-y-auto ${embedded ? 'min-h-[50vh]' : 'px-4 py-4'}`}>
        {messages.map((msg) => (
          <motion.div key={msg.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}
            className={`mb-3 flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            {msg.role === 'user' ? (
              <div className="chat-bubble-user">{msg.content}</div>
            ) : (
              <div className="chat-bubble-ai" dangerouslySetInnerHTML={{ __html: formatMarkdown(msg.content) }} />
            )}
          </motion.div>
        ))}
        {typing && (
          <div className="mb-3 flex justify-start">
            <div className="chat-bubble-ai flex gap-1 py-3">
              {[0, 150, 300].map((d) => <span key={d} className="h-2 w-2 animate-bounce rounded-full bg-violet-400" style={{ animationDelay: `${d}ms` }} />)}
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <div className={embedded ? 'mt-2' : 'border-t border-white/10 bg-surface-card/95 p-4'}>
        <div className="flex gap-2">
          <textarea ref={inputRef} value={input} onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend() } }}
            rows={1} placeholder="Ask anything… e.g. log 200g chicken breast"
            className="input-field max-h-24 min-h-[44px] flex-1 resize-none" data-testid="chat-input" />
          <button type="button" onClick={startListening}
            className={`tap-haptic flex h-11 w-11 shrink-0 items-center justify-center rounded-full border ${listening ? 'border-red-500 bg-red-500/20 animate-pulse' : 'border-white/10 hover:bg-white/5'}`}
            data-testid="voice-input">
            <MicrophoneIcon className={`h-5 w-5 ${listening ? 'text-red-400' : 'text-slate-400'}`} />
          </button>
          <button type="button" onClick={() => handleSend()} disabled={!input.trim() || typing}
            className="tap-haptic btn-gradient flex h-11 w-11 shrink-0 items-center justify-center rounded-full disabled:opacity-40" data-testid="chat-send">
            <PaperAirplaneIcon className="h-5 w-5" />
          </button>
        </div>
      </div>

      <FoodSearchModal open={foodSearchOpen} onClose={() => setFoodSearchOpen(false)} userData={userData} onUpdate={onUpdate} initialQuery={foodSearchQuery} />
    </div>
  )
}
