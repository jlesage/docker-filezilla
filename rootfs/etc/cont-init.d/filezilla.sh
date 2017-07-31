#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# The following directory is needed to store host keys.
mkdir -p "$XDG_CONFIG_HOME"/putty

# Looks like FileZilla is not creating this folder automatically.
mkdir -p "$XDG_DATA_HOME"

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
