#!/usr/bin/bash

BASE_DIR="$(dirname "$(realpath "$0")")/../attacks"
ATTACK_SH="$BASE_DIR/attack.sh"

init_check() {
    echo "Checking the initial expected results for the domain resolutions/configuration..."
    dig +short MX  attacker.test                  @10.9.0.5
    sleep 1
    dig +short A   attacker.test                  @10.9.0.5
    sleep 1
    dig +short TXT attacker.test                  @10.9.0.5
    sleep 1
    dig +short TXT selector._domainkey.attacker.test @10.9.0.5
    sleep 1
    dig +short MX  victim.test                    @10.9.0.5
    sleep 1
    dig +short A   victim.test                    @10.9.0.5
    sleep 1
    dig +short TXT victim.test                    @10.9.0.5
    sleep 1
    dig +short TXT mail._domainkey.victim.test    @10.9.0.5
    sleep 1
    dig +short TXT _dmarc.victim.test             @10.9.0.5
}

policy() {
    echo "-------------------------------------------------------"
    echo " *** Checking for authentication configurations... ***"
    echo "-------------------------------------------------------"
    sleep 1
    echo
    echo "-------------------------------------------------------"
    echo " *** Checking for SPF Policy... ***"
    echo "-------------------------------------------------------"
    dig TXT victim.test @10.9.0.5
    sleep 2
    echo
    echo "-------------------------------------------------------"
    echo " *** Checking for DKIM Policy... ***"
    echo "-------------------------------------------------------"
    dig TXT mail._domainkey.victim.test @10.9.0.5
    sleep 2
    echo
    echo "-------------------------------------------------------"
    echo " *** Checking for DMARC Policy... ***"
    echo "-------------------------------------------------------"
    dig TXT _dmarc.victim.test @10.9.0.5
}

fetch_args() {
    read -e -p "Target Email: " target
    read -e -p "Real Sender [attacker email]: " sender
    read -e -p "Fake Sender [Identity you want to steal]: " fake_sender
    read -e -p "Message Body: " message
}

spf_attack() {
    fetch_args
    echo "Running SPF bypass attack..."
    bash "$ATTACK_SH" spf "$sender" "$target" "$message" "$fake_sender"
}

dkim_attack() {
    fetch_args
    echo "Running DKIM bypass attack..."
    bash "$ATTACK_SH" dkim "$sender" "$target" "$message" "$fake_sender"
}

dmarc_attack() {
    fetch_args
    echo "Running DMARC bypass attack..."
    bash "$ATTACK_SH" dmarc "$sender" "$target" "$message" "$fake_sender"
}


banner() {
sleep 1
    cat <<'EOF'
   _____  ___    ___   ___  ____  __  __  ___   _____ ______________ ____
  / ____||  _ \ / _ \ / _ \| ___||  \/  |/ _ \ / ____|_   __|  ____||  _ \
 | (___  | |_) | | | | | | | |_  | \  / | /_\ \| (___   | | | |__   | |_) |
  \___ \ |  _ /| | | | | | |  _| | |\/| |/___\ \____ \  | | |  __|  |    /
  ____) || |   | |_| | |_| | |   | |  | |     \ \___) | | | | |____ | |\ \
 |_____/ |_|    \___/ \___/|_|   |_|  |_|      \_\____/ |_| |______||_| \_\

  ** Welcome to SpoofMaster – SPF/DKIM/DMARC Bypass Demo - SEED Labs **

EOF
sleep 1
}

banner
while true; do
    sleep 1
    read -e -p "spoofmaster> " input
    history -s "$input"
    read -r cmd args <<< "$input"
    case "$cmd" in
        init_check)
            init_check
            ;;
        policy)
            policy
            ;;
        spf)
            spf_attack
            ;;
        dkim)
            dkim_attack
            ;;
        dmarc)
            dmarc_attack
            ;;
        help|h)
            sleep 1
            echo "Usage: $0 <attack_mode> <sender-email> <destination-email> <message> <sender-faker>"
            echo
            echo "------------------------------------------------------------------------------------------"
            echo
            echo "Modes of attack:"
            echo
            echo "   spf:   sends spoofed email as the fake email the attacker provides relying"
            echo "          on misconfiguration of the SPF auth layer"
            echo "   dkim:  sends spoofed email as the fake email the attacker provides relying"
            echo "          on misconfiguration of the DKIM auth layer"
            echo "   dmarc: sends spoofed email as the fake email the attacker provides relying"
            echo "          on misconfiguration of the DMARC auth layer"
            echo
            echo "------------------------------------------------------------------------------------------"
            echo
            echo "Other commands available:"
            echo
            echo "   init_check: check for the initial resulutions/configs - run at the start of the lab"
            echo "   policy: check the current policies for SPF, DKIM and DMARC"
            echo "   clear: clear the terminal"
            echo "   exit: exit SpoofMaster"
            echo
            echo "------------------------------------------------------------------------------------------"
            ;;
        exit|quit)
            echo "Bye."
            break
            ;;
        clear|clr)
            clear
            banner
            ;;
        "") # For when user presses Enter
            ;;
         *)
            echo "Unknown command: $cmd"
            ;;
    esac
done
