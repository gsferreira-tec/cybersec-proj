# Executing the Attacks

- To run the attacks, execute the following command from the shell of the attacker container:

```bash
./attack.sh <attack-mode> <sender-email> <destination-email> <message> <sender-faker>
```
  - <attack-mode> corresponds to 1 of the three auth methods - `spf`, `dkim` or `dmarc`
  - <sender-email> corresponds to the valid domain account to be checked at the receiver
  - <destination-email> corresponds to the victim's account
  - <message> corresponds to the text in the email
  - <fake-sender> corresponds to the account you want to be displayed at the victim's inbox

- Alternative the `Spoofmaster` tool can be used which is essentially a CLI to run the attacks from `attack.sh`.
  - To start the tool run the script `spoofmaster-cli.sh`.
