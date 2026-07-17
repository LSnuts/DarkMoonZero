<!-- 暗月零点 - 根组件 -->
<!-- 管理页面路由切换和过渡动画 -->

<template>
  <!-- 使用 router-view 渲染当前路由组件，并应用过渡动画 -->
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
const transitionName = ref('fade')  // 默认淡入淡出

// 监听路由变化，根据页面方向选择不同过渡效果
watch(() => router.currentRoute.value.path, (to, from) => {
  if (from === '/' && to === '/bar') {
    transitionName.value = 'slide-up'    // 进入酒柜：上滑
  } else if (to === '/') {
    transitionName.value = 'slide-down'  // 回到首页：下滑
  } else {
    transitionName.value = 'fade'        // 其他：淡入淡出
  }
})
</script>

<style>
html, body, #app {
  width: 100%;
  height: 100%;
  overflow: hidden;
}

/* 淡入淡出过渡 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.6s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 上下滑动过渡 */
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
