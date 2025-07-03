#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

function log {
    echo ">>> $*"
}

FILEZILLA_URL="$1"
LIBFILEZILLA_URL="$2"

if [ -z "$FILEZILLA_URL" ]; then
    log "ERROR: FileZilla URL missing."
    exit 1
fi

if [ -z "$LIBFILEZILLA_URL" ]; then
    log "ERROR: libfilezilla URL missing."
    exit 1
fi

#
# Install required packages.
# NOTE: wxwidgets-dev needed for wxrc tool.
#
apk --no-cache add \
    curl \
    clang \
    make \
    binutils \
    pkgconf \
    gettext \
    wxwidgets-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    nettle-dev \
    gnutls-dev \
    sqlite-dev \
    libidn-dev \
    boost-dev \
    wxwidgets-dev \

ln -s ../lib/wx/config/gtk3-unicode-3.2 /$(xx-info sysroot)usr/bin/wx-config-gtk3

# Fix wxWidgets install for cross-compile.
if xx-info is-cross
then
    # Ignore the --host option passed to wx-config.
    sed -i 's/m_host=${input_option_host/#m_host=${input_option_host/' /$(xx-info sysroot)usr/lib/wx/config/gtk3-unicode-3.2
fi

#
# Download sources.
#

log "Downloading FileZilla package..."
mkdir /tmp/filezilla
curl -# -L -f "$FILEZILLA_URL" | tar xJ --strip 1 -C /tmp/filezilla

log "Downloading libfilezilla package..."
mkdir /tmp/libfilezilla
curl -# -L -f "$LIBFILEZILLA_URL" | tar xJ --strip 1 -C /tmp/libfilezilla

#
# Compile libfilezilla
#

log "Configuring libfilezilla..."
(
    cd /tmp/libfilezilla && \
    ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-doxygen-doc \
        --enable-shared=no \
        --enable-static=yes \
        --with-pic \
)

log "Compiling libfilezilla..."
# Disable usage of memfd_create() system call, which is not available on
# older kernels (<3.17).  See:
#     https://github.com/jlesage/docker-filezilla/issues/27.
sed -i 's|#define HAVE_MEMFD_CREATE 1|/* #undef HAVE_MEMFD_CREATE */|' /tmp/libfilezilla/config/config.hpp
make -C /tmp/libfilezilla -j$(nproc)

log "Installing libfilezilla..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libfilezilla install

#
# Compile FileZilla
#

log "Configuring FileZilla..."
sed -i 's/--disable-shellext/--disable-shellext --prefix="$prefix" --host=$host_alias/' /tmp/filezilla/configure

(
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    cd /tmp/filezilla && \
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig xdgopen=/usr/bin/xdg-open ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --enable-shared=no \
        --enable-static=yes \
        --with-pic \
        --with-pugixml=builtin \
        --without-dbus \
        --disable-autoupdatecheck \
        --disable-manualupdatecheck \
        --with-wx-config=$(xx-info sysroot)usr/bin/wx-config-gtk3 \
        --with-wx-prefix=$(xx-info sysroot)usr \
)

log "Compiling FileZilla..."
make -C /tmp/filezilla -j$(nproc)

log "Installing FileZilla..."
make DESTDIR=/tmp/filezilla-install -C /tmp/filezilla install
