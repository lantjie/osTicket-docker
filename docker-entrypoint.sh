#!/bin/sh
set -e

CONFIG=/var/www/html/include/ost-config.php
SETUP_DIR=/var/www/html/setup

# Remove the installer once osTicket has been installed, so it can't be
# re-run by a visitor. Detected by OSTINSTALLED being TRUE in ost-config.php.
if [ -f "$CONFIG" ] && grep -qE "define\s*\(\s*['\"]OSTINSTALLED['\"]\s*,\s*TRUE" "$CONFIG"; then
    if [ -d "$SETUP_DIR" ]; then
        rm -rf "$SETUP_DIR"
        echo "osTicket: installed — removed $SETUP_DIR"
    fi
    # Config should be read-only once install completes.
    chmod 0644 "$CONFIG" || true
fi

exec "$@"
