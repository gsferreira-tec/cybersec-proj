#!/usr/bin/env bash
# Push edited zone files into the running DNS container and reload BIND.
# Run from the project root:  ./bind/reload-zones.sh
set -e

CONTAINER="dns-server-10.9.0.5"
ZONES_DIR="$(dirname "$0")/zones"

for zone in db.victim.test db.attacker.test; do
    docker cp "$ZONES_DIR/$zone" "$CONTAINER:/etc/bind/$zone"
    docker exec "$CONTAINER" chown root:bind "/etc/bind/$zone"
    docker exec "$CONTAINER" chmod 640 "/etc/bind/$zone"
done

docker exec "$CONTAINER" rndc reload
echo "Zones reloaded."