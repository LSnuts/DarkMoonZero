// 暗月零点 - 应用入口
// 创建 Vue 应用并安装 Pinia 状态管理和 Vue Router

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

const app = createApp(App)
app.use(createPinia())  // 安装 Pinia 状态管理
app.use(router)         // 安装 Vue Router
app.mount('#app')       // 挂载到 #app 节点
