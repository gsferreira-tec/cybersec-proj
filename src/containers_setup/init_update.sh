#!/usr/bin/bash

VICTIM_MAIL="victim-mail-10.9.0.6"
ATTACKER="attacker-sender-10.9.0.7"
RUNME="/home/seed/init-setup/RUNME-1ST.sh"

echo "Updating and mail-server..."
echo
docker exec "$VICTIM_MAIL" apt update && apt full-upgrade -y
docker exec "$VICTIM_MAIL" apt install tcpdump -y
echo
sleep 1
echo "Updating attacker env..."
echo
docker exec "$ATTACKER"  bash "$RUNME"
sleep 1
echo
echo "Done"
