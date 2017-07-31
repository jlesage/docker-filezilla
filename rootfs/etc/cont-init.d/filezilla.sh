#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Make sure required directories exist.
mkdir -p "$XDG_CONFIG_HOME"/filezilla # For FileZilla config.
mkdir -p "$XDG_CONFIG_HOME"/leafpad   # For LeafPad config.
mkdir -p "$XDG_CONFIG_HOME"/putty     # Needed to store host keys.
mkdir -p "$XDG_DATA_HOME"             # Looks like FileZilla is not creating this folder automatically.

# Copy default configuration files.
[ -f "$XDG_CONFIG_HOME"/filezilla/filezilla.xml ] || cp -v /defaults/filezilla.xml "$XDG_CONFIG_HOME"/filezilla/
[ -f "$XDG_CONFIG_HOME"/leafpad/leafpadrc ] || cp -v /defaults/leafpadrc "$XDG_CONFIG_HOME"/leafpad/

# Make sure FileZilla is set to used our default editor.
sed -i 's|<Setting name="Default editor">.*|<Setting name="Default editor">2/usr/bin/leafpad</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml
sed -i 's|<Setting name="Always use default editor">.*|<Setting name="Always use default editor">1</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
