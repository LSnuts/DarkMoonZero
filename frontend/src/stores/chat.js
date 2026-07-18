import { defineStore } from 'pinia'
import { ref } from 'vue'

const STORAGE_KEY = 'darkmoon_session'

const API_BASE = import.meta.env.VITE_API_BASE || ''

function getApiOrigin() {
  if (API_BASE) {
    try {
      return new URL(API_BASE).origin
    } catch {
      return API_BASE.replace(/\/$/, '')
    }
  }
  return `${location.protocol}//${location.host}`
}

function getWsUrl() {
  if (API_BASE) {
    try {
      const url = new URL(API_BASE)
      return `${url.protocol === 'https:' ? 'wss:' : 'ws:'}//${url.host}/ws`
    } catch {
      return `${location.protocol === 'https:' ? 'wss:' : 'ws:'}//${API_BASE.replace(/^https?:\/\//, '').replace(/\/$/, '')}/ws`
    }
  }
  return `${location.protocol === 'https:' ? 'wss:' : 'ws:'}//${location.host}/ws`
}

export { API_BASE }

function loadSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : {}
  } catch {
    return {}
  }
}

function saveSession(state) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch {}
}

function clearSession() {
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch {}
}

export const useChatStore = defineStore('chat', () => {
  const saved = loadSession()

  const sessionId = ref(saved.sessionId || '')
  const displayName = ref(saved.displayName || '')
  const drinkId = ref(saved.drinkId ?? null)
  const drinkColor = ref(saved.drinkColor || '')
  const isMixed = ref(saved.isMixed || false)
  const messages = ref([])
  const isConnected = ref(false)

  let ws = null
  let connectionResolve = null
  let connectionPromise = null

  function persist() {
    saveSession({
      sessionId: sessionId.value,
      displayName: displayName.value,
      drinkId: drinkId.value,
      drinkColor: drinkColor.value,
      isMixed: isMixed.value,
    })
  }

  function generateSessionId() {
    return 'dmz_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8)
  }

  function connectWebSocket() {
    if (ws && ws.readyState === WebSocket.OPEN) return

    ws = new WebSocket(getWsUrl())

    ws.onopen = () => {
      isConnected.value = true
      if (connectionResolve) {
        connectionResolve()
        connectionResolve = null
        connectionPromise = null
      }
      persist()
    }

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data)
      messages.value.push(msg)
      if (messages.value.length > 200) {
        messages.value.shift()
      }
    }

    ws.onclose = () => {
      isConnected.value = false
      if (connectionResolve) {
        connectionResolve()
        connectionResolve = null
        connectionPromise = null
      }
      if (sessionId.value) {
        setTimeout(() => connectWebSocket(), 3000)
      }
    }

    ws.onerror = () => {
      ws.close()
    }
  }

  function waitForConnection() {
    if (connectionPromise) return connectionPromise
    connectionPromise = new Promise((resolve) => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        resolve()
        connectionPromise = null
      } else {
        connectionResolve = resolve
      }
    })
    return connectionPromise
  }

  function sendMessage(content) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'chat',
        session_id: sessionId.value,
        content
      }))
    }
  }

  function sendSystemMsg(action) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'system',
        session_id: sessionId.value,
        action
      }))
    }
  }

  async function joinChat(drinkId, mixedDrinkId = null) {
    const resp = await fetch(`${getApiOrigin()}/api/join`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        drink_id: drinkId,
        mixed_drink_id: mixedDrinkId,
        session_id: sessionId.value
      })
    })
    if (!resp.ok) {
      const err = await resp.json()
      throw new Error(err.detail || '加入失败')
    }
    const data = await resp.json()
    displayName.value = data.display_name
    persist()
    return data
  }

  async function leaveChat() {
    sendSystemMsg('leave')
    await fetch(`${getApiOrigin()}/api/leave`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: sessionId.value })
    }).catch(() => {})
    persist()
  }

  function reset() {
    if (ws) {
      ws.close()
      ws = null
    }
    sessionId.value = ''
    displayName.value = ''
    drinkId.value = null
    drinkColor.value = ''
    isMixed.value = false
    messages.value = []
    isConnected.value = false
    clearSession()
  }

  return {
    sessionId, displayName, drinkId, drinkColor, isMixed,
    messages, isConnected,
    generateSessionId, connectWebSocket, waitForConnection, sendMessage, sendSystemMsg,
    joinChat, leaveChat, reset, persist
  }
})
