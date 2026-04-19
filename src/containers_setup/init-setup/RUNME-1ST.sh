#!/usr/bin/env bash

# this is mean to be run in the attacker container
# updating the ubuntu system in the attacker container and installing relvant tools like swaks and espoofer
echo "[*] Updating the System..."
echo ""
sleep 3
cd /home/seed
apt-get update && apt-get full-upgrade -y
apt update && apt full-upgrade -y

sleep 3
echo ""
echo ""
echo "[*]Installing Swaks..."
echo ""
sleep 3
apt-get install swaks -y

# installing requirements for the espoofer tools
sleep 3
echo ""
echo ""
echo "[*] Upgrading pip to latest version..."
echo ""
cd /home/seed/espoofer
python3 -m pip install --upgrade pip
sleep 3
echo ""
echo ""
echo "[*]Installing Dependencies for espoofer tool..."
echo ""
sleep 3
pip install -r requirements.txt
sleep 3
echo ""
echo ""
echo "[*] Initial setup completed!"
