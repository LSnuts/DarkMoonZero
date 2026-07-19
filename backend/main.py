from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from typing import Dict, List
import json
import asyncio
import os

# CORS: 本地开发 + 环境变量 FRONTEND_URL（参考 lsnuts2 方案）
ALLOWED_ORIGINS = [
    "http://localhost:14080", "http://127.0.0.1:14080",
    "http://localhost:5173", "http://127.0.0.1:5173",
]
frontend_url = os.environ.get("FRONTEND_URL")
if frontend_url:
    ALLOWED_ORIGINS.append(frontend_url)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DRINKS = [
    {"id": 1, "name": "教父", "name_en": "Godfather", "color": "#8B4513", "desc": "威士忌与杏仁酒的经典交融"},
    {"id": 2, "name": "莫吉托", "name_en": "Mojito", "color": "#90EE90", "desc": "薄荷与青柠的清凉之选"},
    {"id": 3, "name": "马天尼", "name_en": "Martini", "color": "#F5F5DC", "desc": "金酒与味美思的永恒经典"},
    {"id": 4, "name": "威士忌", "name_en": "Whiskey", "color": "#DAA520", "desc": "纯饮或加冰，各有风味"},
    {"id": 5, "name": "伏特加", "name_en": "Vodka", "color": "#E0E0E0", "desc": "纯粹而热烈"},
    {"id": 6, "name": "金酒", "name_en": "Gin", "color": "#C0C0C0", "desc": "杜松子的芬芳"},
    {"id": 7, "name": "朗姆酒", "name_en": "Rum", "color": "#D2691E", "desc": "海盗与加勒比的浪漫"},
    {"id": 8, "name": "龙舌兰", "name_en": "Tequila", "color": "#F0E68C", "desc": "墨西哥的热情之魂"},
    {"id": 9, "name": "白兰地", "name_en": "Brandy", "color": "#CD853F", "desc": "葡萄酒的升华"},
    {"id": 10, "name": "曼哈顿", "name_en": "Manhattan", "color": "#8B0000", "desc": "威士忌与甜味美思的都市风味"},
    {"id": 11, "name": "血腥玛丽", "name_en": "Bloody Mary", "color": "#DC143C", "desc": "番茄汁与伏特加的独特搭配"},
    {"id": 12, "name": "代基里", "name_en": "Daiquiri", "color": "#FFD700", "desc": "朗姆与青柠的甜美经典"},
    {"id": 13, "name": "边车", "name_en": "Sidecar", "color": "#FFA500", "desc": "白兰地与橙酒的完美融合"},
    {"id": 14, "name": "古典", "name_en": "Old Fashioned", "color": "#A0522D", "desc": "经典中的经典"},
    {"id": 15, "name": "尼格罗尼", "name_en": "Negroni", "color": "#B22222", "desc": "金酒与甜味美思的苦甜交织"},
]

DRINK_COLORS = {d["name"]: d["color"] for d in DRINKS}

user_drink_map: Dict[str, dict] = {}
drink_user_map: Dict[str, str] = {}
active_connections: List[WebSocket] = []
ws_session_map: Dict[int, str] = {}
chat_messages: List[dict] = []
bar_open = True
drink_lock = asyncio.Lock()
connections_lock = asyncio.Lock()


def _get_drink_by_id(drink_id: int):
    return next((d for d in DRINKS if d["id"] == drink_id), None)


def _release_drink(session_id: str):
    if session_id in user_drink_map:
        keys_to_delete = [name for name, sid in drink_user_map.items() if sid == session_id]
        for name in keys_to_delete:
            del drink_user_map[name]
        del user_drink_map[session_id]


async def _broadcast(msg: dict):
    async with connections_lock:
        targets = list(active_connections)
    text = json.dumps(msg, ensure_ascii=False)
    await asyncio.gather(
        *(conn.send_text(text) for conn in targets),
        return_exceptions=True
    )


def _push_message(msg: dict):
    chat_messages.append(msg)
    if len(chat_messages) > 200:
        chat_messages.pop(0)


@app.get("/api/drinks")
def get_drinks():
    return DRINKS


@app.get("/api/drinks/taken")
def get_taken_drinks():
    return list(drink_user_map.keys())


CONSOLE_HTML = r"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>暗月零点 · 管理控制台</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d0805;color:#d4c4a0;font-family:'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center}
.console{background:#1a1008;border:1px solid rgba(255,180,80,0.15);border-radius:12px;padding:36px 40px;width:400px;max-width:90vw}
h1{font-size:22px;font-weight:300;letter-spacing:6px;text-align:center;margin-bottom:8px;color:#d4c4a0}
.sub{font-size:12px;color:#6b5d4b;text-align:center;letter-spacing:2px;margin-bottom:28px}
.card{background:rgba(255,255,255,0.02);border:1px solid rgba(255,180,80,0.08);border-radius:8px;padding:16px;margin-bottom:12px}
.label{font-size:12px;color:#6b5d4b;letter-spacing:1px;margin-bottom:6px}
.value{font-size:18px;letter-spacing:2px}
.value.open{color:#5cb85c}
.value.closed{color:#ff6b6b}
.btn{display:block;width:100%;padding:10px;font-size:14px;letter-spacing:3px;background:transparent;border:1px solid rgba(255,180,80,0.25);color:#b0a090;cursor:pointer;transition:all .3s;font-family:inherit;margin-top:8px;border-radius:6px}
.btn:hover{border-color:rgba(255,180,80,0.5);color:#d4c4a0;box-shadow:0 0 20px rgba(255,180,80,0.08)}
.btn.danger{border-color:rgba(255,107,107,0.25);color:#ff6b6b}
.btn.danger:hover{border-color:rgba(255,107,107,0.5);box-shadow:0 0 20px rgba(255,107,107,0.08)}
.toast{position:fixed;top:20px;left:50%;transform:translateX(-50%);padding:10px 24px;border-radius:8px;font-size:13px;letter-spacing:1px;z-index:999;opacity:0;transition:opacity .3s}
.toast.show{opacity:1}
.toast.ok{background:#1a2e1a;border:1px solid rgba(92,184,92,0.3);color:#5cb85c}
.toast.err{background:#2e1a1a;border:1px solid rgba(255,107,107,0.3);color:#ff6b6b}
</style>
</head>
<body>
<div id="toast" class="toast"></div>
<div class="console">
<h1>暗月零点</h1>
<p class="sub">管理控制台</p>
<div class="card">
<div class="label">营业状态</div>
<div id="hours" class="value">-</div>
<button class="btn" id="toggleHours">切换营业状态</button>
</div>
<div class="card">
<div class="label">已选酒数</div>
<div id="takenCount" class="value">-</div>
<button class="btn danger" id="resetDrinks">重置所有酒杯</button>
</div>
</div>
<script>
const toast=document.getElementById('toast');
function showToast(msg,type){toast.textContent=msg;toast.className='toast '+type+' show';setTimeout(()=>toast.classList.remove('show'),2500)}
async function refresh(){try{
const r=await fetch('/api/admin/status');const d=await r.json();
document.getElementById('hours').textContent=d.bar_open?'营业中':'已打烊';
document.getElementById('hours').className='value'+(d.bar_open?' open':' closed');
document.getElementById('takenCount').textContent=d.taken_count+' / 15';
}catch(e){showToast('获取状态失败','err')}}
document.getElementById('toggleHours').onclick=async()=>{try{
const r=await fetch('/api/admin/toggle-hours',{method:'POST'});
if(r.ok){showToast('已切换营业状态','ok');refresh()}else showToast('操作失败','err');
}catch(e){showToast('请求失败','err')}}
document.getElementById('resetDrinks').onclick=async()=>{try{
const r=await fetch('/api/admin/reset-drinks',{method:'POST'});
if(r.ok){showToast('酒杯已全部重置','ok');refresh()}else showToast('操作失败','err');
}catch(e){showToast('请求失败','err')}}
refresh();
</script>
</body>
</html>"""


@app.get("/console")
def admin_console():
    return HTMLResponse(CONSOLE_HTML)


@app.get("/api/admin/status")
def admin_status():
    return {"bar_open": bar_open, "taken_count": len(drink_user_map)}


@app.post("/api/admin/reset-drinks")
async def admin_reset_drinks():
    async with drink_lock:
        drink_user_map.clear()
        for sid in list(user_drink_map.keys()):
            info = user_drink_map[sid]
            info["is_mixed"] = True
            info["mixed_drink_id"] = None
    sys_msg = {"type": "system", "content": "酒保擦拭了吧台，所有酒杯已重新就位"}
    _push_message(sys_msg)
    await _broadcast(sys_msg)
    return {"ok": True}


@app.post("/api/admin/toggle-hours")
async def admin_toggle_hours():
    global bar_open
    async with drink_lock:
        bar_open = not bar_open
    msg = "老板拉下了卷帘门，酒馆打烊了" if not bar_open else "老板推开了大门，酒馆开始营业"
    sys_msg = {"type": "system", "content": msg}
    _push_message(sys_msg)
    await _broadcast(sys_msg)
    return {"bar_open": bar_open}


@app.post("/api/join")
async def join_chat(data: dict):
    if not bar_open:
        raise HTTPException(status_code=400, detail="酒馆已打烊，请等待重新营业")

    drink_id = data.get("drink_id")
    mixed_drink_id = data.get("mixed_drink_id")
    session_id = data.get("session_id")

    if not drink_id or not session_id:
        raise HTTPException(status_code=400, detail="缺少参数")

    drink = _get_drink_by_id(drink_id)
    if not drink:
        raise HTTPException(status_code=400, detail="未找到该酒")

    display_name = drink["name"]
    drink_color = drink["color"]
    is_mixed = False

    async with drink_lock:
        if mixed_drink_id:
            mixed_drink = _get_drink_by_id(mixed_drink_id)
            if not mixed_drink:
                raise HTTPException(status_code=400, detail="未找到调和酒")
            if mixed_drink["name"] in drink_user_map:
                raise HTTPException(status_code=400, detail=f"{mixed_drink['name']}已被选择，无法用于调和")
            display_name = f"{drink['name']}+{mixed_drink['name']}·特调"
            drink_color = drink["color"]
            is_mixed = True
            drink_user_map[mixed_drink["name"]] = session_id
        else:
            if drink["name"] in drink_user_map:
                raise HTTPException(status_code=400, detail="该酒已被选择，请重新选择或选择调和")
            drink_user_map[drink["name"]] = session_id

        user_drink_map[session_id] = {
            "display_name": display_name,
            "drink_id": drink_id,
            "color": drink_color,
            "is_mixed": is_mixed,
            "mixed_drink_id": mixed_drink_id,
        }

    return {"display_name": display_name, "session_id": session_id}


@app.get("/api/session/check")
async def check_session(session_id: str = ""):
    valid = session_id in user_drink_map
    info = user_drink_map.get(session_id) if valid else None
    return {"valid": valid, "info": info}


@app.post("/api/leave")
async def leave_chat(data: dict):
    async with drink_lock:
        _release_drink(data.get("session_id", ""))
    return {"ok": True}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    async with connections_lock:
        active_connections.append(websocket)
    ws_id = id(websocket)

    try:
        for msg in chat_messages[-50:]:
            await websocket.send_text(json.dumps(msg, ensure_ascii=False))
    except Exception:
        pass

    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            msg_type = msg.get("type")
            session_id = msg.get("session_id", "")

            if session_id:
                ws_session_map[ws_id] = session_id

            if msg_type == "chat":
                content = msg.get("content", "").strip()
                if not content or session_id not in user_drink_map:
                    continue

                user_info = user_drink_map[session_id]
                chat_msg = {
                    "type": "chat",
                    "display_name": user_info["display_name"],
                    "color": user_info.get("color", "#d4c4a0"),
                    "content": content,
                }
                _push_message(chat_msg)
                await _broadcast(chat_msg)

            elif msg_type == "system":
                action = msg.get("action")
                if session_id not in user_drink_map:
                    continue
                user_info = user_drink_map[session_id]
                display_name = user_info["display_name"]

                if action == "join":
                    sys_msg = {
                        "type": "system",
                        "content": f"{display_name} 推门走进了酒馆"
                    }
                elif action == "leave":
                    sys_msg = {
                        "type": "system",
                        "content": f"{display_name} 离开了酒馆"
                    }
                else:
                    continue

                _push_message(sys_msg)
                await _broadcast(sys_msg)

    except WebSocketDisconnect:
        pass
    finally:
        async with connections_lock:
            if websocket in active_connections:
                active_connections.remove(websocket)
        async with drink_lock:
            if ws_id in ws_session_map:
                sid = ws_session_map[ws_id]
                del ws_session_map[ws_id]
                if sid in user_drink_map:
                    display_name = user_drink_map[sid].get("display_name", "")
                    if display_name:
                        leave_msg = {"type": "system", "content": f"{display_name} 暂时离开了酒馆"}
                        _push_message(leave_msg)
                        await _broadcast(leave_msg)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=18080, reload=True)
