<template>
  <router-view v-slot="{ Component, route }">
    <transition :name="transitionName" mode="out-in">
      <component :is="Component" :key="route.path" />
    </transition>
  </router-view>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const transitionName = ref('fade')

watch(() => router.currentRoute.value.path, (to, from) => {
  if (from === '/' && to === '/bar') {
    transitionName.value = 'slide-up'
  } else if (to === '/') {
    transitionName.value = 'slide-down'
  } else {
    transitionName.value = 'fade'
  }
})
</script>

<style>
html, body, #app {
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.6s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active,
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}
.slide-up-enter-from {
  opacity: 0;
  transform: translateY(60px);
}
.slide-up-leave-to {
  opacity: 0;
  transform: translateY(-60px);
}
.slide-down-enter-from {
  opacity: 0;
  transform: translateY(-60px);
}
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(60px);
}
</style>
