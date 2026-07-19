// 暗月零点 - Vite 配置
// 配置开发服务器端口和 API/WebSocket 代理

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 13030,
    proxy: {
      // 将前端 API 请求代理到后端 FastAPI 服务
      '/api': 'http://localhost:18080',
      // 将 WebSocket 请求代理到后端
      '/ws': {
        target: 'ws://localhost:18080',
        ws: true
      }
    }
  }
})
