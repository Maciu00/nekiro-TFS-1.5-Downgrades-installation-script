#!/bin/bash
# ==========================================
#  The Forgotten Server - Full Auto Installer + systemd
#  Author: Maciu00 
# ==========================================

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RAM=$(free -m | awk '/Mem:/ {print $2}')
SWAP=$(free -m | awk '/Swap:/ {print $2}')

PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(hostname -I | awk '{print $1}')
fi
echo -e "[INFO] Server public IP set to: $PUBLIC_IP"


# ------------------------------
#   SWAP CREATION
# ------------------------------

if [ "$RAM" -lt 1000 ] && [ "$SWAP" -lt 4096 ]; then
  echo -e "[INFO] Creating a 4GB swap file..."
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ------------------------------
#   SYSTEM UPDATE
# ------------------------------

echo -e "[INFO] Updating system..."
apt update && apt upgrade -y

echo -e "[INFO] Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt install -y build-essential cmake git \
liblua5.4-dev libboost-all-dev libmysqlclient-dev libssl-dev \
libpugixml-dev libfmt-dev gcc-11 g++-11 apache2 php php-mysql \
mariadb-server mariadb-client phpmyadmin unzip \
libcrypto++-dev libcrypto++-doc libcrypto++-utils

apt autoremove -y


# ------------------------------
#   DOWNLOAD INSTALLER
# ------------------------------

echo -e "[INFO] Cloning or updating Forgotten Server installer repository..."

#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- OTS VERSION SELECTION ---
echo "Select the OTS version to install:"
echo "1) TFS 7.72"
echo "2) TFS 8.0"
echo "3) TFS 8.60"
read -rp "Enter your choice [1-3]: " OTS_CHOICE

# --- SET REPO URL AND BRANCH BASED ON CHOICE ---
REPO_URL="https://github.com/nekiro/TFS-1.5-Downgrades.git"

case "$OTS_CHOICE" in
    1)
        BRANCH="7.72"
        ;;
    2)
        BRANCH="8.0"
        ;;
    3)
        BRANCH="8.60"
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo -e "[INFO] Selected repository: $REPO_URL (branch: $BRANCH)"

# --- CLONE OR UPDATE REPOSITORY ---
cd /root || exit
if [ -d "TFS-1.5-Downgrades" ]; then
    cd TFS-1.5-Downgrades || exit
    git fetch
    git reset --hard
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    git clone -b "$BRANCH" "$REPO_URL"
    cd TFS-1.5-Downgrades || exit
fi
# --- CLONE OR UPDATE REPOSITORY ---
cd /root || exit
if [ -d "TFS-1.5-Downgrades" ]; then
    cd TFS-1.5-Downgrades || exit
    git fetch
    git reset --hard
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    git clone -b "$BRANCH" "$REPO_URL"
    cd TFS-1.5-Downgrades|| exit
fi
# ------------------------------
#   RANDOM DB ACCESS
# ------------------------------

SQL_SUFFIX=$(tr -dc 'a-z0-9' < /dev/urandom | head -c7)
DB_USER="ots_user$(tr -dc '0-9' < /dev/urandom | head -c4)"
DB_SQL="forgottenserver_${SQL_SUFFIX}"
DB_PASS="tibia-$(tr -dc 'a-z0-9' < /dev/urandom | head -c7)"

echo -e "[INFO] Starting MySQL service..."
service mysql start

# ------------------------------
#   CREATE DATABASE
# ------------------------------

mysql -u root <<MYSQL_SCRIPT
DROP DATABASE IF EXISTS \`${DB_SQL}\`;
DROP USER IF EXISTS '${DB_USER}'@'localhost';
DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';

CREATE DATABASE \`${DB_SQL}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_SQL}\`.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_SQL}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;

SET GLOBAL log_bin_trust_function_creators = 1;
MYSQL_SCRIPT

# ------------------------------
#   IMPORT DATABASE
# ------------------------------

echo -e "[INFO] Importing MySQL schema..."

if [ -f mysql/schema.sql ]; then
    mysql -u "${DB_USER}" -p"${DB_PASS}" -h 127.0.0.1 "${DB_SQL}" < ./schema.sql
else
    echo -e "[WARN] mysql/schema.sql not found. Skipping import."
fi

# ------------------------------
#   GENERATE CONFIG.LUA
# ------------------------------

echo -e "[INFO] Creating TFS configuration file (config.lua)..."

cat > config.lua <<EOF
-- TFS Configuration - Auto-generated

mysqlHost = "127.0.0.1"
mysqlUser = "${DB_USER}"
mysqlPass = "${DB_PASS}"
mysqlDatabase = "${DB_SQL}"
mysqlPort = 3306

-- Combat settings
worldType = "pvp"
hotkeyAimbotEnabled = true
protectionLevel = 1
killsToRedSkull = 3
killsToBlackSkull = 6
pzLocked = 60000
removeChargesFromRunes = true
removeChargesFromPotions = true
removeWeaponAmmunition = true
removeWeaponCharges = true
timeToDecreaseFrags = 24 * 60 * 60

-- Connection
ip = "$PUBLIC_IP"
loginProtocolPort = 7171
gameProtocolPort = 7172
statusProtocolPort = 7171
maxPlayers = 100
motd = "Welcome"

-- Map settings
mapName = "world"
mapAuthor = "Nekiro"

-- Rates
rateExp = 5
rateSkill = 3
rateLoot = 2
rateMagic = 3
rateSpawn = 1
EOF

# ------------------------------
#   BUILD TFS
# ------------------------------

echo -e "[INFO] Building The Forgotten Server..."

mkdir -p build
cd build || exit

cmake .. \
  -DCMAKE_C_COMPILER=/usr/bin/gcc-11 \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++-11 \
  -DCrypto++_INCLUDE_DIR=/usr/include/crypto++ \
  -DCrypto++_LIBRARIES=/usr/lib/x86_64-linux-gnu/libcryptopp.so

make -j$(nproc)

echo -e "[INFO] Moving tfs binary..."
mv tfs ../
chmod +x ../tfs

# ------------------------------
#   CREATE ACCOUNT AND PLAYER
# ------------------------------

ACCOUNT_NAME="111111"
ACCOUNT_PASS="password123"
PLAYER_NAME="PlayerTest"

echo -e "[INFO] Creating account and player..."

mysql -u root <<MYSQL_SCRIPT
USE \`${DB_SQL}\`;

INSERT INTO accounts (name, password, type, premium_ends_at, email, creation) 
VALUES ("${ACCOUNT_NAME}", SHA1("${ACCOUNT_PASS}"), 1, 0, "", UNIX_TIMESTAMP());

SET @account_id = LAST_INSERT_ID();

INSERT INTO players
(name, group_id, account_id, level, vocation, health, healthmax, experience,
 lookbody, lookfeet, lookhead, looklegs, looktype, lookaddons, direction, maglevel,
 mana, manamax, manaspent, soul, town_id, posx, posy, posz, conditions, cap, sex, 
 lastlogin, lastip, save, skull, skulltime, lastlogout, blessings, onlinetime, 
 deletion, balance, offlinetraining_time, offlinetraining_skill, stamina,
 skill_fist, skill_fist_tries, skill_club, skill_club_tries, skill_sword, skill_sword_tries,
 skill_axe, skill_axe_tries, skill_dist, skill_dist_tries, skill_shielding, skill_shielding_tries,
 skill_fishing, skill_fishing_tries)
VALUES
("${PLAYER_NAME}", 1, 1, 1, 1, 150, 150, 0,
 78, 95, 94, 93, 136, 0, 2, 0,
 0, 0, 0, 100, 1, 100, 100, 7, NULL, 400,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 43200, -1, 2520,
 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0);
MYSQL_SCRIPT

# ------------------------------
#   SYSTEMD SERVICE
# ------------------------------

echo -e "[INFO] Creating systemd service..."

cat > /etc/systemd/system/tfs.service <<EOF
[Unit]
Description=The Forgotten Server
After=network.target mysql.service
Requires=mysql.service

[Service]
Type=simple
WorkingDirectory=/root/forgottenserver-install-linux
ExecStart=/root/forgottenserver-install-linux/tfs
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tfs.service

# ------------------------------
#   PHPMYADMIN SETUP
# ------------------------------

ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin
systemctl restart apache2



# ------------------------------
#   DONE
# ------------------------------
echo -e ""
echo -e "${GREEN}=============================================="
echo -e "   INSTALLATION COMPLETED SUCCESSFULLY!"
echo -e "==============================================${NC}"
echo -e ""

echo -e "${YELLOW}=== Game Account Info ========================${NC}"
echo "  Account created:"
echo "      Login:    ${ACCOUNT_NAME}"
echo "      Password: ${ACCOUNT_PASS}"
echo -e ""

echo -e "${YELLOW}=== Database Credentials =====================${NC}"
echo "  Database name: ${DB_SQL}"
echo "  Username:      ${DB_USER}"
echo "  Password:      ${DB_PASS}"
echo -e ""

echo -e "${YELLOW}=== TFS Server Commands ======================${NC}"
echo "  Manual start:"
echo "      cd /root/forgottenserver-install-linux && ./tfs"
echo ""
echo "  Systemd:"
echo "      systemctl start tfs"
echo "      systemctl stop tfs"
echo "      systemctl status tfs"
echo -e ""

echo -e "${GREEN}=============================================="
echo -e "   Made in Poland 🇵🇱  "
echo -e "==============================================${NC}"
echo -e ""