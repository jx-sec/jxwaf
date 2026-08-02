#!/bin/bash
# ==============================================================================
# JXWAF Cloud_user 构建脚本（Go 版本）
#
# 使用方法:
#   ./build.sh              # 构建前端 + Docker镜像
#   ./build.sh frontend     # 仅构建前端
#   ./build.sh docker       # 仅构建Docker镜像（需要先构建前端）
#   ./build.sh binary       # 仅构建Go二进制（本地开发用）
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

build_frontend() {
    echo -e "${YELLOW}[1/2] 构建前端...${NC}"
    cd "$SCRIPT_DIR/front-end"
    npm install --registry=https://registry.npmmirror.com
    npm run build
    cd "$SCRIPT_DIR"

    echo -e "${YELLOW}[2/2] 复制前端构建产物到 static/...${NC}"
    rm -rf "$SCRIPT_DIR/static"
    cp -r "$SCRIPT_DIR/front-end/dist" "$SCRIPT_DIR/static"
    echo -e "${GREEN}前端构建完成${NC}"
}

build_binary() {
    echo -e "${YELLOW}构建 Go 二进制...${NC}"
    cd "$SCRIPT_DIR"
    CGO_ENABLED=0 go build -ldflags="-w -s" -o jxwaf_user_console .
    echo -e "${GREEN}Go 二进制构建完成: jxwaf_user_console${NC}"
}

build_docker() {
    echo -e "${YELLOW}构建 Docker 镜像...${NC}"
    # Docker 镜像不再在容器内编译前端，需确保 static/ 已有构建产物
    if [ ! -d "$SCRIPT_DIR/static" ] || [ -z "$(ls -A "$SCRIPT_DIR/static")" ]; then
        echo -e "${YELLOW}static 目录为空，先构建前端...${NC}"
        build_frontend
    fi
    docker build -t jxwaf_user_console:latest .
    echo -e "${GREEN}Docker 镜像构建完成: jxwaf_user_console:latest${NC}"
}

case "${1:-all}" in
    frontend)
        build_frontend
        ;;
    binary)
        build_binary
        ;;
    docker)
        build_docker
        ;;
    all)
        build_frontend
        build_docker
        ;;
    *)
        echo "用法: $0 [frontend|binary|docker|all]"
        exit 1
        ;;
esac
