#!/usr/bin/env bash
set -euo pipefail
sudo systemctl stop postgresql
sudo -u postgres rm -f /var/lib/postgresql/14/main/standby.signal || true
sudo systemctl start postgresql
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
