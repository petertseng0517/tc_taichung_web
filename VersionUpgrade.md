# 版本升級 SOP

Docker 管理的優勢：新版本與舊版本可同時運行，確認無誤後再切換，隨時可回滾。

---

## 範例情境

- PHP 8.3 → 9.0
- Apache 2.x → 3.x（隨 PHP image 內建）

---

## 一、建立新版本目錄

**不修改原有目錄**，複製一份新的：

```bash
cp -r joomla-php8 joomla-php9
```

目錄結構：
```
taichung/
├── joomla-php8/    ← 舊版，繼續運行
├── joomla-php9/    ← 新版，待測試
```

---

## 二、修改新版 Dockerfile

編輯 `joomla-php9/Dockerfile`，更新 `FROM` 那行：

```dockerfile
# 舊
FROM php:8.3-apache

# 新
FROM php:9.0-apache
```

> Apache 版本由 PHP 官方 image 內建決定，不需另外指定。
> 如需指定特定 Apache 版本，改用 `FROM php:9.0-apache` 並另外安裝。

---

## 三、修改新版 docker-compose.yml

編輯 `joomla-php9/docker-compose.yml`，**所有容器名稱加上版本號**避免衝突：

| 項目 | 舊版 | 新版 |
|------|------|------|
| web 容器 | `joomla_web` | `joomla9_web` |
| db 容器 | `joomla_db` | `joomla9_db` |
| pma 容器 | `joomla_pma` | `joomla9_pma` |
| phpMyAdmin port | `8081` | `8083` |

---

## 四、準備網站與資料庫

```bash
# 建立必要目錄
mkdir -p joomla-php9/html joomla-php9/db_data

# 複製網站檔案（如需測試相同內容）
cp -r joomla-php8/html/. joomla-php9/html/

# 匯出舊資料庫
docker exec joomla_db mysqldump -u root -proot_secret hlm_home26 > /tmp/migrate.sql

# 啟動新容器
cd joomla-php9 && docker compose up -d --build

# 匯入資料到新容器（等容器啟動後）
docker exec -i joomla9_db mysql -u root -proot_secret hlm_home26 < /tmp/migrate.sql
```

---

## 五、測試新版本

確認新容器正常運作：

```bash
docker ps                          # 確認容器狀態為 Up
docker logs joomla9_web            # 查看是否有錯誤
```

瀏覽器測試（在 NPM 新增一筆測試用 Proxy Host）：

| 設定 | 值 |
|------|----|
| Domain | `php9-test.local`（加入本機 hosts）|
| Forward Hostname | `joomla9_web` |
| Forward Port | `80` |

開啟 `http://php9-test.local` 確認網站功能正常。

---

## 六、切換正式流量（確認無誤後）

到 NPM 管理介面（`http://127.0.0.1:81`）：

1. 找到舊版的 Proxy Host（原本指向 `joomla_web`）
2. 點選編輯
3. 將 **Forward Hostname** 改為 `joomla9_web`
4. 儲存

流量即切換到新版，舊容器仍在運行備用。

---

## 七、觀察期（建議 1～2 週）

```bash
# 持續監看新容器 log
docker logs -f joomla9_web

# 確認資料庫正常
docker exec -it joomla9_db mysql -u root -proot_secret -e "SHOW TABLES FROM hlm_home26;"
```

---

## 八、確認無誤後，停止舊版容器

```bash
cd joomla-php8 && docker compose down
```

> 目錄與資料保留，若需回滾執行 `docker compose up -d` 並在 NPM 改回即可。

---

## 回滾步驟

若新版出現問題，快速回滾：

```bash
# 重新啟動舊容器
cd joomla-php8 && docker compose up -d
```

到 NPM 將 Proxy Host 的 Forward Hostname 改回 `joomla_web`，完成回滾。

---

## 版本對照表（請自行維護）

| 目錄 | PHP 版本 | 狀態 |
|------|---------|------|
| joomla-php7 | 7.4 | 運行中 |
| joomla-php8 | 8.3 | 運行中 |
| joomla-php9 | 9.0 | 待測試 |
