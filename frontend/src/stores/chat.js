import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useChatStore = defineStore('chat', () => {
  const sessionId = ref('')
  const displayName = ref('')
  const drinkId = ref(null)
  const drinkColor = ref('')
  const isMixed = ref(false)
  const messages = ref([])
  const isConnected = ref(false)
  let ws = null
  let connectionResolve = null

  function generateSessionId() {
    return 'dmz_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8)
  }

  function connectWebSocket() {
    if (ws && ws.readyState === WebSocket.OPEN) return

    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = location.host
    ws = new WebSocket(`${protocol}//${host}/ws`)

    ws.onopen = () => {
      isConnected.value = true
      if (connectionResolve) {
        connectionResolve()
        connectionResolve = null
      }
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
      setTimeout(() => connectWebSocket(), 3000)
    }

    ws.onerror = () => {
      ws.close()
    }
  }

  function waitForConnection() {
    return new Promise((resolve) => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        resolve()
      } else {
        connectionResolve = resolve
      }
    })
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
        display_name: displayName.value,
        action
      }))
    }
  }

  async function joinChat(drinkId, mixedDrinkId = null) {
    const resp = await fetch('/api/join', {
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
    return data
  }

  async function leaveChat() {
    sendSystemMsg('leave')
    await fetch('/api/leave', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: sessionId.value })
    }).catch(() => {})
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
  }

  return {
    sessionId, displayName, drinkId, drinkColor, isMixed,
    messages, isConnected,
    generateSessionId, connectWebSocket, waitForConnection, sendMessage, sendSystemMsg,
    joinChat, leaveChat, reset
  }
})
