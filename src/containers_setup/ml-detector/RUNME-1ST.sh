#!/bin/bash

echo"[*] Installing dependencies"
apt-get update -q 
apt-get install -y -q python3-pip
pip3 install --break-system-packages -r requirements.txt
