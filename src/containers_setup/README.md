# Attacker Container Setup

- Before running the script `attack.sh` there are a few tools that need to be installed.
- Upon entering the interactive shell of the attacker container with the command `docksh <container_id>` we perform the follwing steps:
  - Navigate to `/home/seed/init_setup`
  - Run the script `run_me_1st.sh` - the system will be updated and the necessary tools will be installed.
  - Naviagate to `/home/seed/attack` and run the attack script - `attack.sh`
