#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
if [ ! -f /config/machine-id ]; then
    echo "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

# Make sure required directories exist.
mkdir -p "$XDG_CONFIG_HOME"/filezilla # For FileZilla config.
mkdir -p "$XDG_CONFIG_HOME"/putty     # Needed to store host keys.
mkdir -p "$XDG_DATA_HOME"             # Looks like FileZilla is not creating this folder automatically.

# Copy default configuration files.
[ -f "$XDG_CONFIG_HOME"/filezilla/filezilla.xml ] || cp -v /defaults/filezilla.xml "$XDG_CONFIG_HOME"/filezilla/

# Make sure FileZilla is set to use our default editor.
sed -i 's|<Setting name="Default editor">.*|<Setting name="Default editor">2/usr/bin/filezilla_editor</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml
sed -i 's|<Setting name="Always use default editor">.*|<Setting name="Always use default editor">1</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml

# vim: set ft=sh :
