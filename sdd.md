# 專案名稱：Joomla 舊站 Docker 解耦架構重建 (包含反向代理與 SSL 準備)

## 1. 專案目標
建立一個具備「高擴充性」與「開發/正式環境一致性」的 Docker 架構。將網路層（反向代理、SSL）與應用層（Joomla、MySQL）徹底解耦，分為兩個獨立的 `docker-compose.yml`。此架構能確保在本地端測試完成後，可無縫轉移至醫院正式 VM 上運作，並支援未來多網域與多專案的擴充。

## 2. 核心架構規格 (Infrastructure Specification)
本專案分為兩個獨立的 Stack，並透過外部 Docker 網路進行通訊。

### 2.0 前置作業：共用網路 (Shared Network)
所有需要對外提供 Web 服務的容器，都必須連接至此外部網路。
* **Network Name:** `web-proxy`
* **建立指令:** `docker network create web-proxy`

---

### 2.1 Stack A: 反向代理伺服器 (Nginx Proxy Manager)
負責統一接收外部的 HTTP (80) 與 HTTPS (443) 流量，管理 Let's Encrypt SSL 憑證，並將請求轉發至後端對應的容器。
* **Image:** `jc21/nginx-proxy-manager:latest`
* **Container Name:** `npm_server`
* **Ports:** * `80:80` (HTTP 流量與 SSL 驗證)
  * `443:443` (HTTPS 流量)
  * `81:81` (NPM 管理後台)
* **Volumes:**
  * `./data:/data`
  * `./letsencrypt:/etc/letsencrypt`
* **Networks:** * `web-proxy`

---

### 2.2 Stack B: Joomla 應用程式與資料庫
此區塊為 Joomla 的核心運行環境。**注意：Web 容器不直接暴露 Port 給 Host 主機，而是透過 `web-proxy` 網路交由 NPM 轉發。**

#### 2.2.1 Web Server (Joomla 應用程式)
* **Image:** `php:8.3-apache` (指定使用 8.3 版本)
* **Container Name:** `joomla_web`
* **Ports:** 移除對外暴露 (不設定 ports)，僅在容器內部運作 80 Port。
* **Volumes:**
  * `./html:/var/www/html` (放置 Joomla 原始碼)
  * `./config/custom.ini:/usr/local/etc/php/conf.d/custom.ini` (PHP 自訂設定檔)
* **Networks:** * `web-proxy` (與 NPM 通訊)
  * `default` (與資料庫通訊)
* **必要依賴 (Dockerfile 或 Command 處理):** * 必須安裝並啟用 Joomla 運作必備的 PHP 擴展：`mysqli`, `pdo_mysql`, `gd`, `zip`。
  * 啟用 Apache 的 `mod_rewrite` 模組。
  * 需將 `/var/www/html` 的擁有者設為 `www-data:www-data` 以確保快取寫入權限。

#### 2.2.2 Database Server (MySQL)
* **Image:** `mysql:5.7`
* **Container Name:** `joomla_db`
* **Ports:** 僅限容器內部網路，不對 Host 暴露。
* **Volumes:**
  * `./db_data:/var/lib/mysql` (資料庫持久化)
* **Environment:**
  * `MYSQL_ROOT_PASSWORD=root_secret`
  * `MYSQL_DATABASE=hlm_home26`
  * `MYSQL_USER=joomla_user`
  * `MYSQL_PASSWORD=joomla_pass`
* **Networks:**
  * `default` (僅限 Stack B 內部通訊)

#### 2.2.3 Database GUI (phpMyAdmin)
* **Image:** `phpmyadmin/phpmyadmin`
* **Container Name:** `joomla_pma`
* **Ports:** `8081:80` (供開發者直接透過 IP:8081 管理資料庫)
* **Environment:**
  * `PMA_HOST=joomla_db` (需正確連線至上述 MySQL 容器)
* **Networks:**
  * `default`

---

## 3. 目錄結構與檔案要求
請依照以下解耦後的結構生成專案骨架與設定檔，需產出兩個獨立的資料夾與對應的 `docker-compose.yml`：

```text
/
├── npm-proxy/                     # Stack A：反向代理管家目錄
│   ├── docker-compose.yml         # NPM 專屬設定檔 (需宣告 external network)
│   ├── data/                      # NPM 資料庫與設定掛載點
│   └── letsencrypt/               # SSL 憑證掛載點
│
├── joomla-app/                    # Stack B：Joomla 應用程式目錄
│   ├── docker-compose.yml         # Joomla 專屬設定檔 (需宣告 external network)
│   ├── config/
│   │   └── custom.ini             # 包含 expose_php = Off 以及 upload_max_filesize = 64M
│   ├── html/                      # Joomla 原始碼掛載點
│   ├── db_data/                   # 資料庫掛載點
│   └── .gitignore                 # 忽略 db_data/ 與環境變數敏感資訊
│
└── setup.sh                       # (選配) 一鍵建立 web-proxy 網路並啟動兩個 Stack 的腳本
```