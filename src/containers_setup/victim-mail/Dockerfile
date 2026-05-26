FROM handsonsecurity/seed-ubuntu:large

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Pre-seed debconf so postfix doesn't ask interactive questions during apt-get
# ---------------------------------------------------------------------------
RUN echo "postfix postfix/mailname string mail.victim.test"     | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# ---------------------------------------------------------------------------
# Install Postfix + Dovecot + OpenDKIM + OpenDMARC + SPF policy daemon
# (all stock Ubuntu packages — no docker-mailserver-specific quirks)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        postfix \
        postfix-pcre \
        dovecot-core \
        dovecot-imapd \
        dovecot-lmtpd \
        # opendkim \
        # opendkim-tools \
        rspamd \
        opendmarc \
        postfix-policyd-spf-python \
        rsyslog \
        ca-certificates \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Copy our configuration files into place
# ---------------------------------------------------------------------------
COPY config/postfix/main.cf            /etc/postfix/main.cf
COPY config/postfix/master.cf          /etc/postfix/master.cf
COPY config/postfix/vmailbox           /etc/postfix/vmailbox
COPY config/postfix/virtual            /etc/postfix/virtual
COPY config/dovecot/dovecot.conf       /etc/dovecot/dovecot.conf
COPY config/dovecot/users              /etc/dovecot/users
# COPY config/opendkim.conf              /etc/opendkim.conf
COPY config/rspamd/worker-proxy.inc    /etc/rspamd/local.d/worker-proxy.inc
COPY config/rspamd/dkim_signing.conf   /etc/rspamd/local.d/dkim_signing.conf
COPY config/opendmarc.conf             /etc/opendmarc.conf
COPY config/policyd-spf.conf           /etc/postfix-policyd-spf-python/policyd-spf.conf

# Entry point — provisions users, fixes perms, starts daemons
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 25 143

CMD ["/usr/local/bin/entrypoint.sh"]
