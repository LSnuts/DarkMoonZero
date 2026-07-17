// 暗月零点 - 聊天状态管理（Pinia Store）
// 管理 WebSocket 连接、会话信息、消息历史和加入/离开逻辑

import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useChatStore = defineStore('chat', () => {
  // ===== 响应式状态 =====
  const sessionId = ref('')         // 当前会话的唯一标识
  const displayName = ref('')       // 用户在聊天中显示的名称
  const drinkId = ref(null)         // 所选酒的 ID
  const drinkColor = ref('')        // 所选酒的颜色
  const isMixed = ref(false)        // 是否为调和酒
  const messages = ref([])          // 消息历史列表
  const isConnected = ref(false)    // WebSocket 连接状态

  let ws = null                     // WebSocket 实例
  let connectionResolve = null      // 用于等待连接建立的 Promise 回调

  // ===== 工具函数 =====

  // 生成唯一会话 ID（dmz_ 前缀 + 时间戳 + 随机字符串）
  function generateSessionId() {
    return 'dmz_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8)
  }

  // ===== WebSocket 连接管理 =====

  // 建立 WebSocket 连接，支持断线自动重连（3 秒后重试）
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

    // 收到消息时追加到消息列表，最多保留 200 条
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data)
      messages.value.push(msg)
      if (messages.value.length > 200) {
        messages.value.shift()
      }
    }

    ws.onclose = () => {
      isConnected.value = false
      setTimeout(() => connectWebSocket(), 3000)  // 3 秒后自动重连
    }

    ws.onerror = () => {
      ws.close()
    }
  }

  // 返回一个 Promise，等待 WebSocket 连接就绪
  function waitForConnection() {
    return new Promise((resolve) => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        resolve()
      } else {
        connectionResolve = resolve
      }
    })
  }

  // ===== 消息发送 =====

  // 发送聊天消息
  function sendMessage(content) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'chat',
        session_id: sessionId.value,
        content
      }))
    }
  }

  // 发送系统消息（加入/离开）
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

  // ===== 加入/离开 =====

  // 调用后端接口加入酒馆，返回用户显示名
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

  // 发送离开消息并调用后端接口释放占用的酒
  async function leaveChat() {
    sendSystemMsg('leave')
    await fetch('/api/leave', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: sessionId.value })
    }).catch(() => {})
  }

  // 重置所有状态（关闭 WebSocket、清空消息等）
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

  // ===== 导出 =====
  return {
    sessionId, displayName, drinkId, drinkColor, isMixed,
    messages, isConnected,
    generateSessionId, connectWebSocket, waitForConnection, sendMessage, sendSystemMsg,
    joinChat, leaveChat, reset
  }
})
