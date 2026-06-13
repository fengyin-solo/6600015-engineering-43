#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

BACKEND_PORT=4000
FRONTEND_PORT=5175

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0

step()  { echo -e "${YELLOW}▶ $1${NC}"; }
pass()  { PASS=$((PASS + 1)); echo -e "${GREEN}✔ $1${NC}"; }
fail_m() { FAIL=$((FAIL + 1)); echo -e "${RED}✖ $1${NC}"; }

check_backend_health() {
  step "检查后端服务 (port ${BACKEND_PORT})..."
  if curl -sf "http://localhost:${BACKEND_PORT}/api/stats" >/dev/null 2>&1; then
    pass "后端服务运行中，/api/stats 可达"
  else
    fail_m "后端服务不可达，请先运行 scripts/dev.sh"
  fi
}

check_frontend_health() {
  step "检查前端服务 (port ${FRONTEND_PORT})..."
  if curl -sf "http://localhost:${FRONTEND_PORT}" >/dev/null 2>&1; then
    pass "前端服务运行中"
  else
    fail_m "前端服务不可达，请先运行 scripts/dev.sh"
  fi
}

check_api_proxy() {
  step "检查前端 → 后端 API 代理..."
  if curl -sf "http://localhost:${FRONTEND_PORT}/api/stats" >/dev/null 2>&1; then
    pass "前端代理 /api → 后端正常"
  else
    fail_m "前端代理 /api 请求失败，检查 vite.config.ts proxy 配置"
  fi
}

check_api_endpoints() {
  step "检查关键 API 端点..."
  local endpoints=("/api/tasks" "/api/stats" "/api/nodes")
  local all_ok=true
  for ep in "${endpoints[@]}"; do
    if curl -sf "http://localhost:${BACKEND_PORT}${ep}" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✔${NC} ${ep}"
    else
      echo -e "  ${RED}✖${NC} ${ep}"
      all_ok=false
    fi
  done
  if [ "$all_ok" = true ]; then
    pass "所有 API 端点正常"
  else
    fail_m "部分 API 端点不可达"
  fi
}

check_api_response_format() {
  step "检查 API 响应格式..."
  local tasks_json
  tasks_json=$(curl -sf "http://localhost:${BACKEND_PORT}/api/tasks" 2>/dev/null)
  if [ -n "$tasks_json" ] && echo "$tasks_json" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'tasks' in d and isinstance(d['tasks'], list)" 2>/dev/null; then
    pass "/api/tasks 返回有效 JSON (含 tasks 数组)"
  else
    fail_m "/api/tasks 响应格式异常，期望 { tasks: [...] }"
  fi

  local stats_json
  stats_json=$(curl -sf "http://localhost:${BACKEND_PORT}/api/stats" 2>/dev/null)
  if [ -n "$stats_json" ] && echo "$stats_json" | python3 -c "import sys,json; d=json.load(sys.stdin); assert all(k in d for k in ['total','running','success','failed'])" 2>/dev/null; then
    pass "/api/stats 返回有效 JSON (含 total/running/success/failed)"
  else
    fail_m "/api/stats 响应格式异常，期望 { total, running, success, failed }"
  fi
}

check_frontend_typecheck() {
  step "前端 TypeScript 类型检查..."
  if (cd "$FRONTEND_DIR" && npx tsc --noEmit 2>&1); then
    pass "TypeScript 类型检查通过"
  else
    fail_m "TypeScript 类型检查失败"
  fi
}

check_frontend_build() {
  step "前端生产构建..."
  if (cd "$FRONTEND_DIR" && npm run build 2>&1); then
    pass "前端构建成功"
  else
    fail_m "前端构建失败"
  fi
}

check_backend_compile() {
  step "后端编译检查..."
  if (cd "$BACKEND_DIR" && mix compile 2>&1); then
    pass "后端编译通过"
  else
    fail_m "后端编译失败"
  fi
}

echo "========================================="
echo "  项目健康检查"
echo "========================================="

echo ""
echo "--- 运行时服务检查 ---"
check_backend_health
check_frontend_health
check_api_proxy
check_api_endpoints
check_api_response_format

echo ""
echo "--- 代码质量检查 ---"
check_frontend_typecheck
check_frontend_build
check_backend_compile

echo ""
echo "========================================="
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}  全部通过！${PASS} 项检查均成功${NC}"
else
  echo -e "${RED}  ${FAIL} 项检查失败，${PASS} 项通过${NC}"
fi
echo "========================================="

[ "$FAIL" -eq 0 ]
