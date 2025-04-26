#!/bin/bash

# Step 1: Install Mosquitto and Clients
echo "Installing Mosquitto and clients..."
sudo apt update
sudo apt install -y mosquitto mosquitto-clients

# Step 2: Create Mosquitto password file
echo "Creating MQTT user..."
sudo mosquitto_passwd -b -c /etc/mosquitto/passwd "${mqtt_username}" "${mqtt_password}"

# Step 3: Configure Mosquitto
CONFIG_FILE="/etc/mosquitto/mosquitto.conf"
echo "Configuring Mosquitto..."
sudo cp /etc/mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf.bak
echo "listener 1883" | sudo tee -a /etc/mosquitto/mosquitto.conf > /dev/null
echo "allow_anonymous false" | sudo tee -a /etc/mosquitto/mosquitto.conf > /dev/null
echo "password_file /etc/mosquitto/passwd" | sudo tee -a /etc/mosquitto/mosquitto.conf > /dev/null


# Step 4: Restart Mosquitto
echo "Restarting Mosquitto..."
sudo systemctl restart mosquitto

echo "Done! MQTT is now secured with username/password."



# Step 5: updating DNS

# === Get Public IP ===
IP=$(curl -s http://checkip.amazonaws.com)

# === Update DuckDNS ===
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${duck_domain_name}&token=${duck_token}&ip=$${IP}")

# === Logging ===
echo "$(date): IP=$${IP} | Response=$${RESPONSE}" >> /var/log/duckdns-update.log
