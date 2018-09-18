#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Generate machine id.
if [ ! -f /etc/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

# Make sure required directories exist.
mkdir -p "$XDG_CONFIG_HOME"/filezilla # For FileZilla config.
mkdir -p "$XDG_CONFIG_HOME"/putty     # Needed to store host keys.
mkdir -p "$XDG_DATA_HOME"             # Looks like FileZilla is not creating this folder automatically.

# Copy default configuration files.
[ -f "$XDG_CONFIG_HOME"/filezilla/filezilla.xml ] || cp -v /defaults/filezilla.xml "$XDG_CONFIG_HOME"/filezilla/

# Make sure FileZilla is set to used our default editor.
sed -i 's|<Setting name="Default editor">.*|<Setting name="Default editor">2/usr/bin/filezilla_editor</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml
sed -i 's|<Setting name="Always use default editor">.*|<Setting name="Always use default editor">1</Setting>|' "$XDG_CONFIG_HOME"/filezilla/filezilla.xml

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
