# 慈濟台中 Web Server

以 Docker 管理的網站伺服器環境，支援多個 PHP 版本並行運作，透過 Nginx Proxy Manager 統一管理對外流量。

---

## 架構

```
外部請求（80 / 443）
        ↓
  Nginx Proxy Manager
   （依 domain 分流）
        ↓
  ┌─────────────────┐
  │  joomla-php8    │  PHP 8.3 + Apache + MySQL 5.7
  │  joomla-php7    │  PHP 7.4 + Apache + MySQL 5.7
  └─────────────────┘
```

每個網站各自包含：
- Web 容器（PHP + Apache）
- 資料庫容器（MySQL）
- phpMyAdmin 容器（資料庫管理介面）

---

## 目錄結構

```
taichung/
├── setup.sh              # 一鍵啟動所有服務
├── .gitignore
├── npm-proxy/            # Nginx Proxy Manager（反向代理）
│   ├── docker-compose.yml
│   └── VersionUpgrade.md # 版本升級 SOP
├── joomla-php8/          # PHP 8.3 網站
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── config/
│   │   └── custom.ini
│   ├── html/             # 網站檔案（不納入 git）
│   └── db_data/          # 資料庫資料（不納入 git）
├── joomla-php7/          # PHP 7.4 網站
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── config/
│   │   └── custom.ini
│   ├── html/             # 網站檔案（不納入 git）
│   └── db_data/          # 資料庫資料（不納入 git）
└── docker_ubuntu.md      # Linux VM 部署指南
```

---

## 管理介面

| 服務 | 網址 | 說明 |
|------|------|------|
| NPM 管理介面 | http://127.0.0.1:81 | 反向代理設定、SSL 憑證 |
| phpMyAdmin (php8) | http://127.0.0.1:8081 | php8 資料庫管理 |
| phpMyAdmin (php7) | http://127.0.0.1:8082 | php7 資料庫管理 |

---

## 快速啟動

### 前置條件
- macOS：需先啟動 OrbStack
- Linux：需確認 Docker daemon 運行中（`sudo systemctl start docker`）

### 啟動所有服務
```bash
./setup.sh
```

### 單獨啟動 / 停止
```bash
# 啟動
docker compose -f joomla-php8/docker-compose.yml up -d
docker compose -f joomla-php7/docker-compose.yml up -d

# 停止
docker compose -f joomla-php8/docker-compose.yml down
docker compose -f joomla-php7/docker-compose.yml down
```

---

## 容器一覽

| 容器名稱 | 說明 |
|---------|------|
| `npm_server` | Nginx Proxy Manager |
| `joomla_web` | PHP 8.3 + Apache |
| `joomla_db` | MySQL 5.7（php8 用） |
| `joomla_pma` | phpMyAdmin（php8 用） |
| `joomla7_web` | PHP 7.4 + Apache |
| `joomla7_db` | MySQL 5.7（php7 用） |
| `joomla7_pma` | phpMyAdmin（php7 用） |

---

## 相關文件

- [docker_ubuntu.md](docker_ubuntu.md) — Linux VM 部署完整指南
- [npm-proxy/VersionUpgrade.md](npm-proxy/VersionUpgrade.md) — PHP / Apache 版本升級 SOP
