# SEED Labs - ***"Email Sender Authentication Misconfiguration"***

- This document serves as a draft for the SEED Labs guide to build from this project.
---
## Introduction

- Here we may exaplin the relevance of the attack in the current technological landscape.
- Secondly we explain how the authentication methods employed more often in the most commmon mail service providers - SPF, DKIM and DMARC - work together to verify the senders identity/signature.
- Thirdly we explain how the inconsistencies/misconfigurations arise and from where they stem as well as how those can create vulnerabilities and how they can be exploited by attackers.
- We also explain that since we created a custom DNS inside the docker network and out mail server is configure to solve to this DNS, then we are able to control the SPF (maybe throw and example that this custom DNS server could be google's as well as the mail server could be gmail).

## Initial Setup and Misconfiguration

- For this lab we will need the follwing sofware/tools:
    - `espoofer` tool from the repository https://github.com/chenjj/espoofer
    - `swaks` tool - can be installed with `apt` package manager in ubuntu
        - use the command: `apt-get update && apt-get install -y swaks`
    - And of course the SEED Labs Ubuntu 20.04 Virtual Machine.

-  To use the espoofer tool inside the attacker container's interactive shell there will be the need to install the packages listed in the `requirements.txt` listed in the project. To do this, once inside the container run the following commands:

```bash
# navigate to the tool's prject directory
cd ~/seed/espoofer

# if recommented/necessary run update on pip
/usr/bin/python3 -m pip install --upgrade pip

# run the install requirements command
pip install -r requirements.txt

# run the tool to confirm the installation and use --list to see available options/cases
python3 espoofer.py --list
```
---
## Description of the Docker Containersand Network
 [TODO - include a diagram of the network created]

---

## Task 1 - Something to do with SPF Check - using `swaks`

- Here we can show some more context in terms of how the configuration files that are already setup set the stage for the SPF attack to be launched:
    - The main implemented piece is the DNS misconfiguration model. The `victim.test` zone intentionally has SPF set to `v=spf1 mx ~all`, no DKIM selector at all, and DMARC set to `p=none` with relaxed alignment, which is exactly the kind of weak posture that can let spoofed mail through or at least avoid strong rejection in a lab setting.
    - Focus on the section named "INTENTIONAL MISCONFIGURATIONS".
```bash
$TTL 86400
@   IN  SOA     ns1.victim.test. admin.victim.test. (
                  2026032201 ; Serial (YYYYMMDDNN)
                  3600       ; Refresh
                  900        ; Retry
                  604800     ; Expire
                  86400 )    ; Minimum TTL

@   IN  NS      ns1.victim.test.
ns1 IN  A       10.9.0.5

; --- MAIL INFRASTRUCTURE ---
; MX: Points to the victim mail server
@       IN  MX  10  mail.victim.test.
mail    IN  A       10.9.0.6

; --- INTENTIONAL MISCONFIGURATIONS (for lab purposes) ---
; SPF: Soft fail (~all) — allows spoofing to pass in many clients
@   IN  TXT     "v=spf1 mx ~all"

; DKIM: No selector/_domainkey record — signatures cannot be verified
; (intentionally missing)

; DMARC: Policy set to none — monitoring only, no enforcement
_dmarc IN TXT   "v=DMARC1; p=none; aspf=r; adkim=r"

```
---

## Task 2 - Something to do with DKIM Check  - using `swaks`
---

## Task 3 - Something to do with DMARC Check - using `swaks`
---

## Task 4 - Some attack tha combines different layers and still is able to spoof emails using the tool `espoofer` for a more complex job
---

# References

- https://github.com/chenjj/espoofer (visited on april 2nd 2026)
- Jiangjun Chen, Vern Paxson, Jian Jiang, "Composition Kills: A Case Study of Email Sender Authentication", USENIX, 2020 [https://www.usenix.org/system/files/sec20-chen-jianjun.pdf]

