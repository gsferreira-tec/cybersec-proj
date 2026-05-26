# `victim-mail/` — Custom Postfix/Dovecot/OpenDKIM container

Replaces the previous `mailserver/docker-mailserver:latest` image. Built on
`handsonsecurity/seed-ubuntu:large` (same base as the attacker container) with
stock Ubuntu packages.

---

## Why we swapped

`docker-mailserver` ships a build of OpenDKIM that, under certain
KeyTable lookup patterns, reports `reason="key not found in DNS"` even when
DNS does return the key correctly. The bug is in the verifier's internal
key validation, not in the DNS layer — which is why every DNS-side debug
(zone file, BIND logs, `dig` from inside the container) looked clean.

The image swap moves us to the stock Ubuntu OpenDKIM package, which doesn't
have this misreport. The textbook `dkim=fail (signature verification failed)`
result now actually appears in `Authentication-Results:`.

---

## What's in here

```
victim-mail/
├── Dockerfile              # FROM handsonsecurity/seed-ubuntu:large
├── entrypoint.sh           # provisions users, fixes perms, starts daemons
├── docker-compose.snippet.yml   # drop-in replacement for the victim-mail service
└── config/
    ├── postfix/
    │   ├── main.cf         # advisory-mode milters, loopback-only mynetworks
    │   ├── master.cf       # adds policyd-spf entry
    │   ├── vmailbox        # alice/bob/user/postmaster @ victim.test
    │   └── virtual         # root → postmaster aliases
    ├── dovecot/
    │   ├── dovecot.conf    # IMAP + LMTP + SASL socket for Postfix
    │   └── users           # passwd-file with plain passwords (lab only)
    ├── opendkim.conf       # Mode sv, Nameservers 10.9.0.5
    ├── opendmarc.conf      # RejectFailures false (advisory mode)
    └── policyd-spf.conf    # *_reject = False (observe, don't enforce)
```

The existing `maildata/opendkim/` tree (KeyTable, SigningTable, TrustedHosts,
and the `keys/victim.test/` keypair) is **reused as-is** — mounted into
`/etc/opendkim/` by the compose file. Nothing in there needs to change.

---

## Wiring it in

1. Drop this whole `victim-mail/` directory into `src/containers_setup/`.
2. Replace the `victim-mail:` service block in `docker-compose.yml` with the
   block from `docker-compose.snippet.yml` (it changes `image:` to `build:`
   and removes the docker-mailserver environment variables).
3. Rebuild: `docker compose build victim-mail && docker compose up -d`.

The other containers (DNS, attacker, webmail, ml-detector) need **no changes**.
Their interfaces to the mail server — SMTP on :25, IMAP on :143, Maildir
under `/var/mail/<user>/Maildir/new/` — are identical.

---

## Validating the fix

From the attacker container:

```bash
# Should resolve victim.test's DKIM key (sanity check on DNS)
dig TXT mail._domainkey.victim.test @10.9.0.5

# Run the dkim attack as before
bash /home/seed/attacks/attack.sh dkim \
    alice@victim.test bob@victim.test "test" attacker@victim.test
```

Then on the host:

```bash
docker exec victim-mail-10.9.0.6 \
    cat /var/mail/bob/Maildir/new/* | grep -i 'authentication-results'
```

You should see something like:

```
Authentication-Results: mail.victim.test;
    dkim=fail reason="signature verification failed" header.d=victim.test
    spf=softfail ...
    dmarc=fail ...
```

instead of the old `dkim=permerror reason="key not found in DNS"`.

---

## Report impact — concrete edit list

These are the only changes the LaTeX report needs:

| Line(s)  | What it says now                                                          | Change to                                                                                                       |
|----------|---------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 306      | `\texttt{docker-mailserver}` (Image column)                              | `\texttt{seed-ubuntu:large} (custom build)`                                                                     |
| 307–308  | "Postfix/Dovecot mail server for `victim.test`; runs SPF, DKIM, and DMARC validation." | Same — still accurate.                                                                                          |
| 346      | `user@victim.test    (hashed, for postfix-accounts.cf)`                  | `user@victim.test    password: seed-lab` (or just delete the line — `postfix-accounts.cf` no longer applies)    |
| 598–609  | The whole `notebox` apologising for the `key not found in DNS` quirk     | **Delete entirely**, OR shrink to: *"`dkim=fail` may be reported with a `reason=` describing either signature mismatch or key retrieval issues; both are forms of failure."* |

Everything else — task instructions, attack commands, DNS zones, expected
header strings, defence-task DKIM key-publication walkthrough, the
ml-detector feature table — stays as written. The lab's pedagogical
structure is unchanged; only the implementation underneath the
`victim-mail` container is swapped.

---

## Optional improvement (not required to fix the bug)

If you want Roundcube-sent mail (`alice@victim.test` → `bob@victim.test` via
the webmail UI) to be **signed** automatically, add `10.9.0.8` to
`maildata/opendkim/TrustedHosts`:

```
127.0.0.1
localhost
10.9.0.8        # webmail (Roundcube) — sign its outbound submissions
```

Without this line, webmail-originated mail goes out unsigned (so the
`dkim=none` result is technically correct but doesn't make for a good
"legitimate mail is signed, attacker mail isn't" contrast in demos).
