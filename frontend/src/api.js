// 统一 API 基址
// DEV 模式走 Vite 代理，生产模式走 VITE_API_BASE 环境变量
// Cloudflare Pages 需设置 VITE_API_BASE=https://api.8000021.xyz

export function getApiBase() {
  if (import.meta.env.DEV) {
    return ''
  }
  return import.meta.env.VITE_API_BASE || ''
}

export function getWsBase() {
  if (import.meta.env.DEV) {
    return ''
  }
  const api = import.meta.env.VITE_API_BASE || ''
  if (api) {
    return api.replace(/^http/, 'ws')
  }
  return ''
}
