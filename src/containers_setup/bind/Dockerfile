FROM ubuntu/bind9:latest

COPY config/named.conf /etc/bind/named.conf
COPY config/named.conf.options /etc/bind/named.conf.options
COPY config/named.conf.local /etc/bind/named.conf.local
COPY zones/db.attacker.test /etc/bind/db.attacker.test
COPY zones/db.victim.test /etc/bind/db.victim.test

RUN chown -R root:bind /etc/bind && \
    chmod 755 /etc/bind && \
    chmod 640 /etc/bind/named.conf \
              /etc/bind/named.conf.options \
              /etc/bind/named.conf.local \
              /etc/bind/db.attacker.test \
              /etc/bind/db.victim.test
