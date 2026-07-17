<template>
  <div class="chat">
    <div class="chat-bg"></div>

    <header class="chat-header">
      <div class="header-left">
        <div class="status-dot" :class="{ connected: chat.isConnected }"></div>
        <span class="status-text">{{ chat.isConnected ? '在线' : '重连中...' }}</span>
      </div>
      <div class="header-center">
        <span class="header-name" :style="{ color: chat.drinkColor }">{{ chat.displayName }}</span>
        <span class="header-divider">·</span>
        <span class="header-title">吧台闲聊</span>
      </div>
      <div class="header-right">
        <button class="header-btn" @click="leaveAndGoBack">离开</button>
      </div>
    </header>

    <div class="messages" ref="messagesRef">
      <template v-for="(msg, i) in chat.messages" :key="i">
        <div v-if="msg.type === 'system'" class="system-msg">{{ msg.content }}</div>
        <div v-else class="bubble" :class="{ own: msg.display_name === chat.displayName }" :style="{ borderLeftColor: getDrinkColor(msg.display_name) }">
          <div class="bubble-name" :style="{ color: getDrinkColor(msg.display_name) }">{{ msg.display_name }}</div>
          <div class="bubble-content">{{ msg.content }}</div>
        </div>
      </template>
      <div v-if="chat.messages.length === 0" class="empty-hint">
        <p>夜晚才刚刚开始……</p>
        <p class="empty-sub">来打个招呼吧</p>
      </div>
    </div>

    <div class="input-area">
      <div class="input-wrapper">
        <input
          ref="inputRef"
          v-model="inputText"
          class="chat-input"
          placeholder="聊聊今晚的故事……"
          @keydown.enter="send"
          maxlength="500"
        />
        <button class="send-btn" @click="send" :disabled="!inputText.trim()">
          <span>发送</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useChatStore } from '../stores/chat'

const router = useRouter()
const chat = useChatStore()

const inputText = ref('')
const messagesRef = ref(null)
const inputRef = ref(null)

onMounted(() => {
  if (!chat.sessionId || !chat.displayName) {
    router.push('/')
    return
  }
  inputRef.value?.focus()
})

onUnmounted(() => {
  // don't reset here - let the user explicitly leave
})

function send() {
  const text = inputText.value.trim()
  if (!text) return
  chat.sendMessage(text)
  inputText.value = ''
  nextTick(() => inputRef.value?.focus())
}

async function leaveAndGoBack() {
  await chat.leaveChat()
  chat.reset()
  router.push('/')
}

function getDrinkColor(displayName) {
  if (displayName === chat.displayName) return chat.drinkColor || '#d4c4a0'
  return '#b8a888'
}

watch(() => chat.messages.length, async () => {
  await nextTick()
  if (messagesRef.value) {
    messagesRef.value.scrollTop = messagesRef.value.scrollHeight
  }
})
</script>

<style scoped>
.chat {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: radial-gradient(ellipse at 50% 0%, #1a1008 0%, #0d0805 50%, #050302 100%);
  position: relative;
}

.chat-bg {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at top, rgba(255, 180, 80, 0.04), transparent 35%),
              linear-gradient(180deg, #110b07 0%, #080503 100%);
  pointer-events: none;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: rgba(0, 0, 0, 0.4);
  border-bottom: 1px solid rgba(255, 180, 80, 0.08);
  position: relative;
  z-index: 2;
  flex-shrink: 0;
}

.header-left,
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 80px;
}

.header-right {
  justify-content: flex-end;
}

.header-center {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #5a4d3b;
  transition: background 0.3s;
}
.status-dot.connected {
  background: #5cb85c;
  box-shadow: 0 0 6px rgba(92, 184, 92, 0.4);
}

.status-text {
  font-size: 12px;
  color: #6b5d4b;
}

.header-name {
  font-size: 15px;
  letter-spacing: 2px;
}

.header-divider {
  color: #3a3025;
}

.header-title {
  font-size: 13px;
  color: #6b5d4b;
  letter-spacing: 2px;
}

.header-btn {
  background: none;
  border: 1px solid rgba(255, 180, 80, 0.15);
  color: #6b5d4b;
  padding: 6px 14px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s;
  font-family: inherit;
  letter-spacing: 1px;
}

.header-btn:hover {
  border-color: rgba(255, 180, 80, 0.4);
  color: #8b7d6b;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 1px;
  position: relative;
  z-index: 1;
}

.messages::-webkit-scrollbar {
  width: 4px;
}
.messages::-webkit-scrollbar-track {
  background: transparent;
}
.messages::-webkit-scrollbar-thumb {
  background: rgba(255, 180, 80, 0.15);
  border-radius: 2px;
}

.system-msg {
  align-self: center;
  font-size: 11px;
  color: #5a4d3b;
  padding: 3px 14px;
  background: rgba(255, 180, 80, 0.04);
  border-radius: 20px;
  letter-spacing: 1px;
  margin: 3px 0;
}

.bubble {
  max-width: 68%;
  border-radius: 4px;
  padding: 3px 10px;
  background: rgba(255, 255, 255, 0.03);
  word-break: break-word;
  border-left: 2px solid rgba(255, 180, 80, 0.2);
}

.bubble.own {
  align-self: flex-end;
  background: rgba(255, 180, 80, 0.06);
  border-left-color: transparent;
  border-right: 2px solid rgba(255, 180, 80, 0.25);
}

.bubble-name {
  font-size: 11px;
  margin-bottom: 1px;
  letter-spacing: 1px;
  opacity: 0.75;
}

.bubble.own .bubble-name {
  text-align: right;
}

.bubble-content {
  font-size: 14px;
  color: #f1d9ae;
  line-height: 1.35;
}

.msg-row.own .bubble-content {
  color: #fff;
}

.empty-hint {
  text-align: center;
  margin-top: 80px;
  color: #3a3025;
}

.empty-hint p {
  font-size: 16px;
  letter-spacing: 3px;
  margin-bottom: 6px;
}

.empty-sub {
  font-size: 13px !important;
  color: #2a2015;
}

.input-area {
  padding: 16px 20px;
  background: rgba(0, 0, 0, 0.3);
  border-top: 1px solid rgba(255, 180, 80, 0.08);
  flex-shrink: 0;
  position: relative;
  z-index: 2;
}

.input-wrapper {
  display: flex;
  gap: 10px;
  max-width: 700px;
  margin: 0 auto;
}

.chat-input {
  flex: 1;
  padding: 12px 16px;
  font-size: 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 180, 80, 0.12);
  border-radius: 8px;
  color: #d4c4a0;
  outline: none;
  transition: border-color 0.3s;
  font-family: inherit;
}

.chat-input::placeholder {
  color: #3a3025;
}

.chat-input:focus {
  border-color: rgba(255, 180, 80, 0.3);
}

.send-btn {
  padding: 0 20px;
  background: transparent;
  border: 1px solid rgba(255, 180, 80, 0.25);
  color: #b0a090;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s;
  border-radius: 8px;
  font-family: inherit;
  letter-spacing: 2px;
}

.send-btn:hover:not(:disabled) {
  border-color: rgba(255, 180, 80, 0.5);
  color: #d4c4a0;
  box-shadow: 0 0 15px rgba(255, 180, 80, 0.08);
}

.send-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}
</style>
