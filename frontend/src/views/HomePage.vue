<template>
  <div class="home">
    <div class="vignette"></div>
    <div class="warm-glow"></div>

    <div class="content">
      <div class="lamp">
        <div class="lamp-light"></div>
      </div>

      <h1 class="title">暗月零点</h1>
      <p class="subtitle">Dark Moon Zero</p>
      <p class="tagline">夜色已深，酒馆的门为你敞开</p>

      <button class="enter-btn" @click="enterTavern">
        <span class="btn-text">进入酒馆</span>
        <span class="btn-glow"></span>
      </button>
    </div>

    <div class="particles">
      <span v-for="n in 20" :key="n" class="particle"
        :style="{ '--delay': `${n * 0.7}s`, '--x': `${Math.random() * 100}%` }"></span>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useChatStore } from '../stores/chat'

const router = useRouter()
const chat = useChatStore()

function enterTavern() {
  chat.reset()
  chat.sessionId = chat.generateSessionId()
  router.push('/bar')
}
</script>

<style scoped>
.home {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(ellipse at 50% 80%, #1a0f0a 0%, #0d0805 40%, #050302 100%);
  position: relative;
  overflow: hidden;
}

.vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.8) 100%);
  pointer-events: none;
}

.warm-glow {
  position: absolute;
  width: 600px;
  height: 600px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(255, 180, 80, 0.06) 0%, transparent 70%);
  top: 55%;
  left: 50%;
  transform: translate(-50%, -50%);
  animation: glowPulse 4s ease-in-out infinite;
  pointer-events: none;
}

@keyframes glowPulse {
  0%, 100% { opacity: 0.5; transform: translate(-50%, -50%) scale(1); }
  50% { opacity: 1; transform: translate(-50%, -50%) scale(1.1); }
}

.content {
  text-align: center;
  z-index: 1;
  position: relative;
  margin-bottom: -80px;
}

.lamp {
  position: relative;
  width: 60px;
  height: 80px;
  margin: 0 auto 40px;
}

.lamp::before {
  content: '';
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 4px;
  height: 30px;
  background: linear-gradient(to bottom, #8b7355, transparent);
}

.lamp-light {
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 40px;
  height: 50px;
  background: radial-gradient(ellipse at center, #ffd700 0%, #ff8c00 40%, transparent 70%);
  border-radius: 50%;
  animation: lampFlicker 3s ease-in-out infinite;
  filter: blur(4px);
}

@keyframes lampFlicker {
  0%, 100% { opacity: 0.6; transform: translateX(-50%) scaleY(1); }
  25% { opacity: 0.8; transform: translateX(-50%) scaleY(1.1); }
  50% { opacity: 0.5; transform: translateX(-50%) scaleY(0.9); }
  75% { opacity: 0.7; transform: translateX(-50%) scaleY(1.05); }
}

.title {
  font-size: 64px;
  font-weight: 300;
  letter-spacing: 16px;
  color: #d4c4a0;
  text-shadow: 0 0 40px rgba(255, 180, 80, 0.3), 0 2px 4px rgba(0,0,0,0.5);
  margin-bottom: 8px;
}

.subtitle {
  font-size: 16px;
  letter-spacing: 8px;
  color: #8b7d6b;
  margin-bottom: 16px;
  text-transform: uppercase;
}

.tagline {
  font-size: 15px;
  color: #6b5d4b;
  margin-bottom: 60px;
  letter-spacing: 2px;
}

.enter-btn {
  position: relative;
  padding: 14px 48px;
  font-size: 18px;
  letter-spacing: 6px;
  background: transparent;
  border: 1px solid rgba(255, 180, 80, 0.3);
  color: #d4c4a0;
  cursor: pointer;
  transition: all 0.5s ease;
  overflow: hidden;
  font-family: inherit;
}

.enter-btn:hover {
  border-color: rgba(255, 180, 80, 0.8);
  box-shadow: 0 0 40px rgba(255, 180, 80, 0.15), inset 0 0 40px rgba(255, 180, 80, 0.05);
  transform: translateY(-2px);
}

.enter-btn:active {
  transform: translateY(0);
}

.btn-text {
  position: relative;
  z-index: 1;
}

.btn-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  background: radial-gradient(circle, rgba(255, 180, 80, 0.2), transparent);
  transition: all 0.5s ease;
  pointer-events: none;
}

.enter-btn:hover .btn-glow {
  width: 300px;
  height: 300px;
  margin: -150px 0 0 -150px;
}

.particles {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.particle {
  position: absolute;
  top: -4px;
  width: 2px;
  height: 2px;
  background: rgba(255, 200, 100, 0.4);
  border-radius: 50%;
  left: var(--x);
  animation: fall var(--delay) linear infinite;
}

@keyframes fall {
  0% { transform: translateY(-10px) translateX(0); opacity: 0; }
  10% { opacity: 1; }
  100% { transform: translateY(100vh) translateX(30px); opacity: 0; }
}
</style>
