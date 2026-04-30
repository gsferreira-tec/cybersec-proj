# Seed Labs - "Email Sender Authentication Miscofiguration (SPF/DKIM/DMARC)"

- This repository contains the documentaition as well as the implementation of a CyberSecurity project developed during the duration of a Cyber Security course from the Masters in Electronics Engineering @ FEUP.

- The objective of this project is to develop a strategy to perform an attack that is currently relevant in the field of CyberSecurity and provide a possible solution to the attack that could solve the vulnerability exploited or at least help mitigate it.

---
# Brief Overview

- This project focuses on understanding the possible vulnerabilities that can be exploited stemming from the misconfiguration of email authentication methods lioke SPF, DKIM and DMARC. For that purpose we create a lab environment using containers to create a safe network where these exploits can be demonstrated with the objective of makin it available to the SEED Labs repository.
- Another objective of this project is to harden these security measures by proposing some additions to the authentication process that might eliminate/mitigate the risks exposed by these misconfigurations
- While these authentication patters are widely adopted, the misconfigurations or insconsistencies introduced by different providers/developers continue to allow ***phishing*** and ***spoofing*** attacks, representing real instancies of the vulnerabilities OWASP A02:2025 (Security Misconfiguration) and A07:2025 (Authentication Failures).
- To setup the network we followed the example from other SEED Labs which use **Docker** to setup the necessary containers and the connections. Using this method we could demonstrate how an attacker could explore these vulnerabilities to forge the identities of legitimate domains. The environment includes:
  - **DNS Server**: intentionally configured with vulnerable register for the domain `victim.test`.
  - **Email Server(Postfix/Dovecot)**: acts as a target which processes the forged messages.
  - **Webmail Page**: for those more unfamiliar with the terminal approch we have a webmail page running which is a mockup of a traditional email page like gmail or outlook... This makes the lab seem more familiar and motivate people to learn about this topic.
  - **Attack Tools**: using `swaks` for a more manual approach in step-by-step methodic approch to allow SEED Labs users to better understand each of the authentication methods. Using `espoofer` for more complex attacks combining the bypass of more than one of the authentication methods.

- The final objective is that CyberSecurity students, professionals or enthusiats understand the origin of the vulnerabilies better preparing them to come up with solution and additional security measures they can implement @ the DNS and MTA levels.

---
# Structure/Contributing

- The `docs` directory contains all the documentation develop during this project, including the deliverables (project proposal, intermediate/final presentations and any other documents that may be relevant to this project and help understand it).

- The `src` directory will contain all the code and scripting that will be developed in order to perform the attack(and this will probably consist of `python` and `shell` scripts).

---
# Tools

- The tools required/used in this project are:
  - `docker` - installed with `sudo apt install docker.io`
  - `espoofer` - obtained from https://github.com/chenjj/espoofer.git
  - `swaks` - installed only on the attacker container when running the script `RUNME-1ST.sh`
  - `pip` - installed only on the attacker container when running the script `RUNME-1ST.sh`
  - `virtualbox-7.2` - installed with `sudo apt install virtualbox-7.2`
  - `SEED-Labs-Ubuntu-20.04` - obtained from https://seedsecuritylabs.org/labsetup.html

---
# Commands

- In either the victim or attack container, one can test the resolution of its domain name, in the DNS server, via the following command:
  - nslookup mail.attacker.test 10.9.0.5
- For the victim counterpart:
  - nslookup mail.victim.test 10.9.0.5

---
# Notes for Lab improvement - by the Professor

- Use as 1st misconfiguration the non-existant `spf`.
  - Only after that show the soft-fail misconfiguration
