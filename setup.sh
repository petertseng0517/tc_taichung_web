#!/bin/bash
# 執行前需確認orb已啟動
set -e

echo "=== Step 1: 建立共用 Docker 網路 web-proxy ==="
docker network create web-proxy 2>/dev/null || echo "網路 web-proxy 已存在，略過。"

echo ""
echo "=== Step 2: 啟動 Stack A (NPM 反向代理) ==="
docker-compose -f npm-proxy/docker-compose.yml up -d

echo ""
echo "=== Step 3: 啟動 Stack B (Joomla 應用程式) ==="
docker-compose -f joomla-php8/docker-compose.yml up -d --build

echo ""
echo "=== 完成 ==="
echo "NPM 管理介面: http://127.0.0.1:81"
echo "phpMyAdmin:   http://127.0.0.1:8081"
