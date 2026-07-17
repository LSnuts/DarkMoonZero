import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('../views/HomePage.vue')
  },
  {
    path: '/bar',
    name: 'bar',
    component: () => import('../views/BarCounter.vue')
  },
  {
    path: '/chat',
    name: 'chat',
    component: () => import('../views/ChatRoom.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
