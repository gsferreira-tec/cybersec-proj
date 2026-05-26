#!/usr/bin/bash
# ============================================================================
# victim-mail entrypoint
#
# Runs at container start. Three jobs:
#   1. Provision the vmail system user and per-account Maildirs
#   2. Fix permissions on the OpenDKIM key (must be readable by the
#      opendkim user — wrong perms is the #1 cause of "key not found in DNS"
#      misreports in stock OpenDKIM, which is why we're switching off
#      docker-mailserver in the first place)
#   3. Start rsyslog, opendkim, opendmarc, postfix, dovecot — in that order
# ============================================================================
set -e

# ---------------------------------------------------------------------------
# Virtual mail user + Maildir layout under /var/mail/<user>/Maildir
# ---------------------------------------------------------------------------
if ! getent group vmail >/dev/null; then
    groupadd -g 5000 vmail
fi
if ! id vmail >/dev/null 2>&1; then
    useradd -g vmail -u 5000 -d /var/mail -s /usr/sbin/nologin vmail
fi

for user in alice bob postmaster; do
    mkdir -p "/var/mail/${user}/Maildir/new" \
             "/var/mail/${user}/Maildir/cur" \
             "/var/mail/${user}/Maildir/tmp"
done
chown -R vmail:vmail /var/mail
chmod -R 700 /var/mail/*/Maildir

# ---------------------------------------------------------------------------
# OpenDKIM permissions
# The opendkim user MUST own the private key and the key directory must
# be 700.  If you skip this, OpenDKIM silently fails the key load and
# reports "key not found in DNS" even when DNS is fine — exactly the
# bug we're escaping from.
# ---------------------------------------------------------------------------
# chown -R opendkim:opendkim /etc/opendkim
# find /etc/opendkim -type d -exec chmod 750 {} \;
# find /etc/opendkim -type f -exec chmod 640 {} \;
# chmod 700 /etc/opendkim/keys
# chmod 700 /etc/opendkim/keys/victim.test
# chmod 600 /etc/opendkim/keys/victim.test/mail.private

# ---------------------------------------------------------------------------
# Rspamd DKIM key permissions
# Rspamd must be able to read the private key used for signing.
# ---------------------------------------------------------------------------
# chown -R _rspamd:_rspamd /etc/rspamd
# find /etc/rspamd -type d -exec chmod 755 {} \;
# find /etc/rspamd -type f -exec chmod 644 {} \;
# chmod 750 /etc/rspamd/keys
# chmod 640 /etc/rspamd/keys/victim.test.mail.key
# chown _rspamd:_rspamd /etc/rspamd/keys/victim.test.mail.key


# Postfix needs to talk to opendkim via inet socket on localhost:8891,
# so no socket-group fiddling required.

# Make sure runtime dirs exist (some Ubuntu images skip them)
# mkdir -p /var/run/opendkim   && chown opendkim:opendkim   /var/run/opendkim
mkdir -p /var/run/opendmarc  && chown opendmarc:opendmarc /var/run/opendmarc
mkdir -p /var/spool/postfix/private

# Compile Postfix lookup tables (vmailbox, virtual aliases)
postmap /etc/postfix/vmailbox
postmap /etc/postfix/virtual

# ---------------------------------------------------------------------------
# Start services
# ---------------------------------------------------------------------------
cat > /etc/resolv.conf << 'EOF'
nameserver 10.9.0.5
search victim.test
options edns0
EOF

service rsyslog   start

# testing OpenDKIM
echo "[*] Verifying DNS resolution from inside container..."
if dig +short TXT mail._domainkey.victim.test @10.9.0.5 | grep -q 'DKIM1'; then
    echo "    DNS OK >> DKIM key found"
else
    echo "    WARNING >> DKIM key not found in DNS. Check bind/zones/db.victim.test"
fi
service rspamd    start
service opendmarc start

service postfix   start
service dovecot   start

echo "==================================================================="
echo " victim-mail-10.9.0.6 ready"
echo "   - Postfix listening on :25"
echo "   - Dovecot IMAP on :143, LMTP on unix socket"
echo "   - Rspamd milter active"
echo "   - OpenDMARC milter on localhost:8893"
echo "   - Mail delivered to /var/mail/<user>/Maildir/new/"
echo "==================================================================="

# Keep the container alive and stream mail logs so 'docker logs' is useful
touch /var/log/mail.log
exec tail -F /var/log/mail.log /var/log/mail.err 2>/dev/null
