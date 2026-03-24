# VM 部署指南（Ubuntu/Debian）

---

## 一、拿到 VM 後第一件事

### 確認系統資訊
```bash
cat /etc/os-release       # 確認 Linux 版本
uname -a                  # 確認核心版本
df -h                     # 確認磁碟空間
free -h                   # 確認記憶體
```

### 更新系統套件
```bash
sudo apt-get update && sudo apt-get upgrade -y
```
> 建議每次登入後先執行，確保系統套件是最新的。

---

## 二、帳號與權限管理

### 建立專用部署帳號（不要直接用 root）
```bash
sudo adduser deploy                        # 建立帳號
sudo usermod -aG sudo deploy               # 給予 sudo 權限
su - deploy                                # 切換到該帳號
```

### 設定 SSH 金鑰登入（停用密碼登入）
在本機執行：
```bash
ssh-keygen -t ed25519 -C "your_email"     # 產生金鑰
ssh-copy-id deploy@<VM_IP>                # 複製公鑰到 VM
```

在 VM 上停用密碼登入：
```bash
sudo nano /etc/ssh/sshd_config
# 找到以下兩行，確認設定為：
# PasswordAuthentication no
# PermitRootLogin no
sudo systemctl restart sshd
```

### 設定防火牆
```bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw status
```

---

## 三、安裝 Docker

```bash
curl -fsSL https://get.docker.com | sh
```

### 讓目前使用者可以執行 docker（不用每次加 sudo）
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 確認安裝成功
```bash
docker --version
docker compose version
```

### 設定開機自動啟動
```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
```

---

## 四、設定 GitHub 並 Clone 專案

### 安裝 Git
```bash
sudo apt install git -y
git --version
```

### 設定 Git 身份
```bash
git config --global user.name "你的名字"
git config --global user.email "你的信箱"
```

### 產生 SSH 金鑰並加到 GitHub
```bash
ssh-keygen -t ed25519 -C "your_email"
cat ~/.ssh/id_ed25519.pub    # 複製這段公鑰
```
到 GitHub → Settings → SSH and GPG keys → New SSH key，貼上公鑰。

### 測試連線
```bash
ssh -T git@github.com
```

### Clone 專案
```bash
cd /opt
sudo mkdir taichung
sudo chown deploy:deploy taichung
git clone git@github.com:<你的帳號>/<repo名稱>.git taichung
cd taichung
```

---

## 五、部署 Docker

### 建立必要目錄結構
```bash
mkdir -p joomla-php8/html joomla-php8/db_data
mkdir -p joomla-php7/html joomla-php7/db_data
mkdir -p npm-proxy/data npm-proxy/letsencrypt
```

### 執行部署腳本
```bash
chmod +x setup.sh
./setup.sh
```

### 確認容器運作
```bash
docker ps
docker compose -f joomla-php8/docker-compose.yml logs
docker compose -f joomla-php7/docker-compose.yml logs
```

---

## 六、資料庫遷移

### 從舊伺服器匯出資料庫
在舊伺服器執行：
```bash
mysqldump -u root -p hlm_home26 > hlm_home26_backup.sql
```

### 將備份檔複製到 VM
在本機執行：
```bash
scp hlm_home26_backup.sql deploy@<VM_IP>:/opt/taichung/
```

### 匯入到新的資料庫容器
```bash
# 等容器啟動後執行
docker exec -i joomla_db mysql -u root -proot_secret hlm_home26 < hlm_home26_backup.sql

# php7 站（如有需要）
docker exec -i joomla7_db mysql -u root -proot_secret hlm_home26 < hlm_home26_backup.sql
```

### 確認資料庫
```bash
docker exec -it joomla_db mysql -u root -proot_secret -e "SHOW DATABASES;"
```

---

## 七、部署後確認清單

```
[ ] docker ps 所有容器狀態為 Up
[ ] NPM 管理介面可開啟（http://<VM_IP>:81）
[ ] NPM 已設定 Proxy Host 指向各容器
[ ] 網站可正常瀏覽
[ ] phpMyAdmin 可登入並看到資料
[ ] 防火牆已啟用，只開放必要 port
[ ] SSH 密碼登入已停用
[ ] 設定 SSL 憑證（在 NPM 內申請 Let's Encrypt）
```

---

## 八、日常維護指令

```bash
# 查看所有容器狀態
docker ps

# 查看容器 log
docker compose -f joomla-php8/docker-compose.yml logs -f

# 重啟某個容器
docker compose -f joomla-php8/docker-compose.yml restart

# 更新專案並重新部署
git pull
docker compose -f joomla-php8/docker-compose.yml up -d --build

# 資料庫備份
docker exec joomla_db mysqldump -u root -proot_secret hlm_home26 > backup_$(date +%Y%m%d).sql
```
