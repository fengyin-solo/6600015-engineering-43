#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

step()  { echo -e "${YELLOW}▶ $1${NC}"; }
ok()    { echo -e "${GREEN}✔ $1${NC}"; }
fail()  { echo -e "${RED}✖ $1${NC}"; exit 1; }

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    fail "$1 未安装，请先安装后重试"
  fi
}

echo "========================================="
echo "  项目依赖安装"
echo "========================================="

step "检查必要工具..."
check_cmd elixir
check_cmd node
check_cmd npm
ok "工具链检查通过"

step "安装后端 Elixir 依赖..."
(cd "$BACKEND_DIR" && mix deps.get) || fail "后端依赖安装失败"
ok "后端依赖安装完成"

step "安装前端 npm 依赖..."
(cd "$FRONTEND_DIR" && npm install) || fail "前端依赖安装失败"
ok "前端依赖安装完成"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  所有依赖安装完毕！${NC}"
echo -e "${GREEN}  运行 scripts/dev.sh 启动开发环境${NC}"
echo -e "${GREEN}=========================================${NC}"
