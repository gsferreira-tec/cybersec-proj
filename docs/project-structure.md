# Project Structure Overview

- This is the result of running the command `tree` in the `cybersec-proj/` directory to showcase the project's current structure:

```bash
cybersec-proj/
├── docs
│   ├── cleanup.sh
│   ├── IEEEabrv.bib
│   ├── IEEEtran.bst
│   ├── IEEEtran.cls
│   ├── intermediate-presentation.pdf
│   ├── intermediate-presentation.tex
│   ├── OurBibliography.bib
│   ├── proj-proposal.pdf
│   ├── proj-proposal.tex
│   ├── references.bib
│   ├── SEED-Labs.md
│   ├── SSR-Docker-Diagram-Darkmode.png
│   ├── SSR-Docker-Diagram.png
│   └── template.tex
├── README.md
└── src
    ├── containers_setup
    │   ├── attacks
    │   │   ├── attack.sh
    │   │   ├── README.md
    │   │   ├── spf-network-traffic.log
    │   │   └── spf-spoof-attack.log
    │   ├── bind
    │   │   ├── config
    │   │   │   ├── named.conf
    │   │   │   ├── named.conf.local
    │   │   │   └── named.conf.options
    │   │   ├── Dockerfile
    │   │   └── zones
    │   │       ├── db.attacker.test
    │   │       └── db.victim.test
    │   ├── docker-compose.yml
    │   ├── espoofer
    │   │   ├── common
    │   │   │   ├── common.py
    │   │   │   ├── __init__.py
    │   │   │   ├── mail_sender.py
    │   │   │   └── __pycache__
    │   │   │       ├── common.cpython-38.pyc
    │   │   │       ├── __init__.cpython-38.pyc
    │   │   │       └── mail_sender.cpython-38.pyc
    │   │   ├── config.py
    │   │   ├── dkim
    │   │   │   ├── arcsign.py
    │   │   │   ├── arcverify.py
    │   │   │   ├── asn1.py
    │   │   │   ├── canonicalization.py
    │   │   │   ├── crypto.py
    │   │   │   ├── dkimsign.py
    │   │   │   ├── dkimverify.py
    │   │   │   ├── dknewkey.py
    │   │   │   ├── dnsplug.py
    │   │   │   ├── __init__.py
    │   │   │   ├── __main__.py
    │   │   │   ├── __pycache__
    │   │   │   │   ├── asn1.cpython-38.pyc
    │   │   │   │   ├── canonicalization.cpython-38.pyc
    │   │   │   │   ├── crypto.cpython-38.pyc
    │   │   │   │   ├── dnsplug.cpython-38.pyc
    │   │   │   │   ├── __init__.cpython-38.pyc
    │   │   │   │   └── util.cpython-38.pyc
    │   │   │   └── util.py
    │   │   ├── dkimkey
    │   │   ├── espoofer.py
    │   │   ├── exploits_builder.py
    │   │   ├── images
    │   │   │   ├── email-authentication-flow.png
    │   │   │   ├── gmail-spoofing-demo.png
    │   │   │   └── list_caseid.png
    │   │   ├── LICENSE
    │   │   ├── papers
    │   │   │   └── composition-kills-USESEC20.pdf
    │   │   ├── __pycache__
    │   │   │   ├── config.cpython-38.pyc
    │   │   │   ├── exploits_builder.cpython-38.pyc
    │   │   │   └── testcases.cpython-38.pyc
    │   │   ├── README.md
    │   │   ├── requirements.txt
    │   │   └── testcases.py
    │   ├── init_setup
    │   │   └── run-me-1st.sh
    │   ├── maildata
    │   │   ├── dovecot-quotas.cf
    │   │   └── postfix-accounts.cf
    │   ├── mail-server-dummy-ui
    │   │   └── app.py
    │   └── README.md
    └── README.md
```
