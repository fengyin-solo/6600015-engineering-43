#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

BACKEND_PORT=4000
FRONTEND_PORT=5175
BACKEND_PID=""
FRONTEND_PID=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step()  { echo -e "${YELLOW}▶ $1${NC}"; }
ok()    { echo -e "${GREEN}✔ $1${NC}"; }
fail()  { echo -e "${RED}✖ $1${NC}"; }

cleanup() {
  echo ""
  echo -e "${YELLOW}正在停止服务...${NC}"
  [ -n "$BACKEND_PID" ]  && kill "$BACKEND_PID"  2>/dev/null && echo -e "${GREEN}✔ 后端已停止${NC}"
  [ -n "$FRONTEND_PID" ] && kill "$FRONTEND_PID" 2>/dev/null && echo -e "${GREEN}✔ 前端已停止${NC}"
  wait 2>/dev/null
  echo -e "${CYAN}再见！${NC}"
  exit 0
}
trap cleanup SIGINT SIGTERM

wait_for_port() {
  local port=$1 name=$2 pid=$3 timeout=30 elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      fail "$name 进程已异常退出"
      return 1
    fi
    if curl -sf "http://localhost:${port}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  fail "$name 在 ${timeout}s 内未就绪 (port ${port})"
  return 1
}

echo "========================================="
echo "  启动开发环境"
echo "========================================="

if [ ! -d "$BACKEND_DIR/deps" ]; then
  step "后端依赖未安装，正在安装..."
  (cd "$BACKEND_DIR" && mix deps.get) || { fail "后端依赖安装失败"; exit 1; }
fi

if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
  step "前端依赖未安装，正在安装..."
  (cd "$FRONTEND_DIR" && npm install) || { fail "前端依赖安装失败"; exit 1; }
fi

step "启动后端 (port ${BACKEND_PORT})..."
(cd "$BACKEND_DIR" && mix run --no-halt) &
BACKEND_PID=$!

step "启动前端 (port ${FRONTEND_PORT})..."
(cd "$FRONTEND_DIR" && npm run dev) &
FRONTEND_PID=$!

echo ""
step "等待服务就绪..."
if wait_for_port "$BACKEND_PORT" "后端" "$BACKEND_PID"; then
  ok "后端已就绪 → http://localhost:${BACKEND_PORT}"
fi
if wait_for_port "$FRONTEND_PORT" "前端" "$FRONTEND_PID"; then
  ok "前端已就绪 → http://localhost:${FRONTEND_PORT}"
fi

echo ""
step "验证 API 连通性..."
API_RESULT=$(curl -sf "http://localhost:${BACKEND_PORT}/api/stats" 2>&1) && {
  ok "API /api/stats 响应正常: $API_RESULT"
} || {
  fail "API /api/stats 请求失败，请检查后端日志"
}

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  开发环境已就绪！${NC}"
echo -e "${GREEN}  前端: http://localhost:${FRONTEND_PORT}${NC}"
echo -e "${GREEN}  后端: http://localhost:${BACKEND_PORT}${NC}"
echo -e "${GREEN}  按 Ctrl+C 停止所有服务${NC}"
echo -e "${GREEN}=========================================${NC}"

wait
