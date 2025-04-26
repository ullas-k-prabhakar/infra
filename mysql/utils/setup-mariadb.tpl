#!/bin/bash


echo "⏳ Waiting for apt lock..."
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
  echo "🔒 Locked. Retrying in 2s..."
  sleep 2
done


# Wait for apt lock to be released
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "⏳ Waiting for apt lock..."
  sleep 5
done


# Add MariaDB official repository
sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release software-properties-common
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Install MariaDB from official repo
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client

sudo mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ mysql_root_password }'; FLUSH PRIVILEGES;"
sudo mariadb -u root -p"${ mysql_root_password }" <<SQL
CREATE DATABASE ${ mysql_db_name };
CREATE USER '${ mysql_user }'@'%' IDENTIFIED BY '${ mysql_user_password }';
GRANT ALL PRIVILEGES ON ${ mysql_db_name }.* TO '${ mysql_user }'@'%';
FLUSH PRIVILEGES;
SQL

sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb

if command -v ufw >/dev/null 2>&1; then
  ufw allow 3306
fi

echo "✅ MariaDB setup complete with remote access."


# Step 5: updating DNS

# === Get Public IP ===
IP=$(curl -s http://checkip.amazonaws.com)

# === Update DuckDNS ===
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${duck_domain_name}&token=${duck_token}&ip=$${IP}")

# === Logging ===
echo "$(date): IP=$${IP} | Response=$${RESPONSE}" >> /var/log/duckdns-update.log
