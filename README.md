# 暗月零点 · Dark Moon Zero

一个充满氛围感的虚拟酒馆聊天应用。选一杯酒，为你的名字染上色彩，推门而入，与深夜的同路人围坐吧台闲聊。

## 功能

- **选酒入座** — 15 种经典鸡尾酒任选，也可将两种酒调和成专属特调
- **实时聊天** — 基于 WebSocket 的吧台闲聊，每个名字都带着酒的颜色
- **营业管理** — 管理控制台可开关酒馆、重置所有酒杯.当然,打样闭店之后无法再进入酒馆,已经在吧台的还可以继续.

## 快速开始

```bash
# 启动后端 (端口 18080)
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 18080 --reload

# 启动前端 (端口 14080)
cd frontend
npm install
npm run dev
```

或直接运行 `start.ps1` 一键启动。

## 管理控制台

打开 `http://localhost:18080/console` 可管理营业状态和重置酒杯。

## 技术栈

| 层    | 技术                          |
|-------|-------------------------------|
| 前端  | Vue 3 + Pinia + Vue Router + Vite |
| 后端  | Python + FastAPI + WebSocket  |

有事联系我,liusu852@yeah.net
不定时查看