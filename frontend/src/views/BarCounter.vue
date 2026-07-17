<template>
  <div class="bar">
    <div class="bar-bg"></div>

    <header class="bar-header">
      <button class="back-btn" @click="goBack">← 退出</button>
      <h2 class="bar-title">酒 柜</h2>
      <span class="bar-subtitle">选一杯今夜属于你的酒</span>
    </header>

    <div class="drinks-grid">
      <div
        v-for="drink in drinks"
        :key="drink.id"
        class="drink-card"
        :class="{
          selected: selectedId === drink.id,
          taken: takenDrinks.includes(drink.name) && selectedId !== drink.id,
          'mix-mode': showMix && selectedId === drink.id
        }"
        :style="{ '--drink-color': drink.color }"
        @click="selectDrink(drink)"
      >
        <div class="drink-glass">
          <div class="glass-liquid" :style="{ background: drink.color }"></div>
          <div class="glass-shine"></div>
        </div>
        <div class="drink-name">{{ drink.name }}</div>
        <div class="drink-en">{{ drink.name_en }}</div>
        <div class="drink-desc">{{ drink.desc }}</div>
        <div v-if="takenDrinks.includes(drink.name)" class="taken-badge">已选</div>
      </div>
    </div>

    <Transition name="modal">
      <div v-if="showMix" class="mix-modal" @click.self="cancelMix">
        <div class="mix-modal-content">
          <h3>调和特调</h3>
          <p class="mix-hint">
            「{{ selectedDrink?.name }}」已被选走<br/>
            请再选一种酒进行调和，名称将变为：
          </p>
          <p class="mix-preview">{{ selectedDrink?.name }} + <span class="mix-highlight">{{ mixDrink?.name || '?' }}</span> · 特调</p>
          <div class="mix-grid">
            <div
              v-for="drink in availableMixDrinks"
              :key="drink.id"
              class="mix-option"
              :class="{ active: mixDrink?.id === drink.id }"
              :style="{ '--drink-color': drink.color }"
              @click="mixDrink = drink"
            >
              <div class="mix-liquid" :style="{ background: drink.color }"></div>
              <span>{{ drink.name }}</span>
            </div>
          </div>
          <div class="mix-actions">
            <button class="mix-btn cancel" @click="cancelMix">取消</button>
            <button class="mix-btn confirm" :disabled="!mixDrink" @click="confirmMix">确认调和</button>
          </div>
        </div>
      </div>
    </Transition>

    <div v-if="errorMsg" class="error-toast">{{ errorMsg }}</div>

    <Transition name="modal">
      <div v-if="showConfirm" class="mix-modal" @click.self="showConfirm = false">
        <div class="mix-modal-content confirm-content">
          <h3>确认选择</h3>
          <div class="confirm-display">
            <div class="confirm-glass">
              <div class="glass-liquid" :style="{ background: currentDrink.color }"></div>
            </div>
            <div class="confirm-name">{{ confirmDisplayName }}</div>
          </div>
          <p class="confirm-hint">确定以这个名字进入酒馆吗？</p>
          <div class="mix-actions">
            <button class="mix-btn cancel" @click="showConfirm = false">再看看</button>
            <button class="mix-btn confirm" @click="enterChat">推门而入</button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useChatStore } from '../stores/chat'

const router = useRouter()
const chat = useChatStore()

const drinks = ref([])
const takenDrinks = ref([])
const selectedId = ref(null)
const selectedDrink = computed(() => drinks.value.find(d => d.id === selectedId.value))
const showMix = ref(false)
const showConfirm = ref(false)
const mixDrink = ref(null)
const currentDrink = ref(null)
const confirmDisplayName = ref('')
const isLoading = ref(true)
const errorMsg = ref('')

const availableMixDrinks = computed(() =>
  drinks.value.filter(d => d.id !== selectedId.value && !takenDrinks.value.includes(d.name))
)

onMounted(async () => {
  if (!chat.sessionId) {
    router.push('/')
    return
  }
  try {
    const [drinksResp, takenResp] = await Promise.all([
      fetch('/api/drinks'),
      fetch('/api/drinks/taken')
    ])
    drinks.value = await drinksResp.json()
    takenDrinks.value = await takenResp.json()
  } catch (e) {
    errorMsg.value = '连接失败，请检查后端是否启动'
  } finally {
    isLoading.value = false
  }
})

function selectDrink(drink) {
  if (!chat.sessionId) return
  errorMsg.value = ''

  if (showMix.value) {
    if (drink.id === selectedId.value) return
    mixDrink.value = drink
    return
  }

  selectedId.value = drink.id
  currentDrink.value = drink

  if (takenDrinks.value.includes(drink.name)) {
    showMix.value = true
    mixDrink.value = null
  } else {
    confirmDisplayName.value = drink.name
    showConfirm.value = true
  }
}

async function confirmMix() {
  if (!mixDrink.value) return
  confirmDisplayName.value = `${selectedDrink.value.name}+${mixDrink.value.name}·特调`
  showMix.value = false
  showConfirm.value = true
}

async function enterChat() {
  try {
    const mixedId = showMix.value || mixDrink.value ? mixDrink.value?.id : null
    await chat.joinChat(currentDrink.value.id, mixedId || null)
    chat.drinkId = currentDrink.value.id
    chat.drinkColor = currentDrink.value.color
    chat.isMixed = !!mixedId

    chat.connectWebSocket()
    await chat.waitForConnection()
    chat.sendSystemMsg('join')

    router.push('/chat')
  } catch (e) {
    errorMsg.value = e.message || '进入失败'
    showConfirm.value = false
    showMix.value = false
  }
}

function cancelMix() {
  showMix.value = false
  selectedId.value = null
  mixDrink.value = null
}

function goBack() {
  chat.reset()
  router.push('/')
}
</script>

<style scoped>
.bar {
  width: 100%;
  height: 100%;
  background: radial-gradient(ellipse at 50% 0%, #1a1008 0%, #0d0805 50%, #050302 100%);
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.bar-bg {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse at 50% 100%, rgba(255, 150, 50, 0.03) 0%, transparent 60%),
    repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(255,255,255,0.01) 2px, rgba(255,255,255,0.01) 3px);
  pointer-events: none;
}

.bar-header {
  text-align: center;
  padding: 30px 20px 10px;
  position: relative;
  z-index: 1;
}

.bar-title {
  font-size: 36px;
  font-weight: 300;
  letter-spacing: 12px;
  color: #d4c4a0;
  text-shadow: 0 0 30px rgba(255, 180, 80, 0.2);
  margin-bottom: 4px;
}

.bar-subtitle {
  font-size: 13px;
  color: #6b5d4b;
  letter-spacing: 3px;
}

.back-btn {
  position: absolute;
  left: 20px;
  top: 30px;
  background: none;
  border: 1px solid rgba(255, 180, 80, 0.2);
  color: #8b7d6b;
  padding: 8px 16px;
  cursor: pointer;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.3s;
  letter-spacing: 2px;
}
.back-btn:hover {
  color: #d4c4a0;
  border-color: rgba(255, 180, 80, 0.5);
}

.drinks-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 16px;
  padding: 20px 30px;
  overflow-y: auto;
  z-index: 1;
  max-width: 900px;
  margin: 0 auto;
  width: 100%;
}

.drinks-grid::-webkit-scrollbar {
  width: 4px;
}
.drinks-grid::-webkit-scrollbar-track {
  background: transparent;
}
.drinks-grid::-webkit-scrollbar-thumb {
  background: rgba(255, 180, 80, 0.2);
  border-radius: 2px;
}

.drink-card {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 180, 80, 0.08);
  border-radius: 12px;
  padding: 20px 12px 14px;
  text-align: center;
  cursor: pointer;
  transition: all 0.4s ease;
  position: relative;
}

.drink-card:hover {
  background: rgba(255, 180, 80, 0.06);
  border-color: rgba(255, 180, 80, 0.25);
  transform: translateY(-4px);
  box-shadow: 0 8px 30px rgba(255, 180, 80, 0.08);
}

.drink-card.selected {
  border-color: var(--drink-color);
  box-shadow: 0 0 20px rgba(255, 180, 80, 0.15);
  background: rgba(255, 180, 80, 0.08);
}

.drink-card.taken {
  opacity: 0.5;
  cursor: not-allowed;
}
.drink-card.taken:hover {
  transform: none;
  box-shadow: none;
}

.drink-glass {
  width: 40px;
  height: 60px;
  margin: 0 auto 12px;
  position: relative;
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 0 0 8px 8px;
  border-top: none;
}

.glass-liquid {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 70%;
  border-radius: 0 0 6px 6px;
  opacity: 0.6;
  transition: opacity 0.3s;
}

.drink-card:hover .glass-liquid {
  opacity: 0.8;
}

.glass-shine {
  position: absolute;
  top: 6px;
  left: 4px;
  width: 6px;
  height: 20px;
  background: linear-gradient(to bottom, rgba(255,255,255,0.3), transparent);
  border-radius: 3px;
}

.drink-name {
  font-size: 16px;
  color: #d4c4a0;
  margin-bottom: 2px;
  letter-spacing: 2px;
}

.drink-en {
  font-size: 11px;
  color: #6b5d4b;
  margin-bottom: 6px;
}

.drink-desc {
  font-size: 11px;
  color: #5a4d3b;
  line-height: 1.4;
}

.taken-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  font-size: 10px;
  color: #ff6b6b;
  border: 1px solid rgba(255, 107, 107, 0.3);
  padding: 2px 6px;
  border-radius: 4px;
}

.mix-modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  backdrop-filter: blur(4px);
}

.mix-modal-content {
  background: #1a1008;
  border: 1px solid rgba(255, 180, 80, 0.2);
  border-radius: 16px;
  padding: 36px 32px;
  max-width: 480px;
  width: 90%;
  text-align: center;
}

.mix-modal-content h3 {
  font-size: 24px;
  font-weight: 300;
  letter-spacing: 6px;
  color: #d4c4a0;
  margin-bottom: 20px;
}

.mix-hint {
  font-size: 14px;
  color: #8b7d6b;
  line-height: 1.8;
  margin-bottom: 16px;
}

.mix-preview {
  font-size: 20px;
  color: #d4c4a0;
  letter-spacing: 3px;
  margin-bottom: 24px;
  padding: 12px;
  background: rgba(255, 180, 80, 0.05);
  border-radius: 8px;
}

.mix-highlight {
  color: var(--drink-color, #ffd700);
}

.mix-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin-bottom: 24px;
}

.mix-option {
  padding: 12px 6px;
  border: 1px solid rgba(255, 180, 80, 0.1);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  text-align: center;
}

.mix-option:hover {
  border-color: rgba(255, 180, 80, 0.3);
  background: rgba(255, 180, 80, 0.05);
}

.mix-option.active {
  border-color: var(--drink-color);
  background: rgba(255, 180, 80, 0.1);
  box-shadow: 0 0 15px rgba(255, 180, 80, 0.1);
}

.mix-option span {
  font-size: 13px;
  color: #b0a090;
  letter-spacing: 1px;
}

.mix-liquid {
  width: 16px;
  height: 24px;
  margin: 0 auto 6px;
  border-radius: 0 0 4px 4px;
  opacity: 0.6;
}

.mix-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.mix-btn {
  padding: 10px 28px;
  font-size: 14px;
  letter-spacing: 2px;
  border: 1px solid rgba(255, 180, 80, 0.3);
  background: transparent;
  color: #d4c4a0;
  cursor: pointer;
  transition: all 0.3s;
  font-family: inherit;
}

.mix-btn:hover {
  border-color: rgba(255, 180, 80, 0.6);
  box-shadow: 0 0 20px rgba(255, 180, 80, 0.1);
}

.mix-btn.confirm {
  border-color: rgba(255, 180, 80, 0.5);
}

.mix-btn.confirm:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.mix-btn.confirm:not(:disabled):hover {
  background: rgba(255, 180, 80, 0.1);
}

.mix-btn.cancel {
  color: #6b5d4b;
  border-color: transparent;
}

.mix-btn.cancel:hover {
  color: #8b7d6b;
}

.confirm-content {
  max-width: 360px;
}

.confirm-display {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin: 20px 0;
}

.confirm-glass {
  width: 50px;
  height: 80px;
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 0 0 10px 10px;
  border-top: none;
  position: relative;
}

.confirm-glass .glass-liquid {
  height: 70%;
}

.confirm-name {
  font-size: 28px;
  color: #d4c4a0;
  letter-spacing: 3px;
}

.confirm-hint {
  font-size: 14px;
  color: #6b5d4b;
  margin-bottom: 20px;
}

.error-toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: #2e1a1a;
  border: 1px solid rgba(255, 107, 107, 0.3);
  color: #ff6b6b;
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 13px;
  letter-spacing: 1px;
  z-index: 200;
  animation: toastIn 0.3s ease;
}
@keyframes toastIn {
  from { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  to { opacity: 1; transform: translateX(-50%) translateY(0); }
}

.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from .mix-modal-content,
.modal-leave-to .mix-modal-content {
  transform: scale(0.9);
}
</style>
