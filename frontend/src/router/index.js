// 暗月零点 - 路由配置
// 定义三个页面的路由：首页、酒柜、聊天室

import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('../views/HomePage.vue')  // 首页：酒馆入口
  },
  {
    path: '/bar',
    name: 'bar',
    component: () => import('../views/BarCounter.vue')  // 酒柜：选酒页面
  },
  {
    path: '/chat',
    name: 'chat',
    component: () => import('../views/ChatRoom.vue')  // 聊天室：吧台闲聊
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
