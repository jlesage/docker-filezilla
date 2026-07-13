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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() {
    echo ">>> $*"
}

FILEZILLA_URL="$1"
LIBFILEZILLA_URL="$2"
FZSSH_URL="$3"

if [ -z "$FILEZILLA_URL" ]; then
    log "ERROR: FileZilla URL missing."
    exit 1
fi

if [ -z "$LIBFILEZILLA_URL" ]; then
    log "ERROR: libfilezilla URL missing."
    exit 1
fi

if [ -z "$FZSSH_URL" ]; then
    log "ERROR: fzssh URL missing."
    exit 1
fi

#
# Install required packages.
# NOTE: wxwidgets-dev needed for wxrc tool.
#
apk --no-cache add \
    curl \
    patch \
    clang \
    meson \
    make \
    binutils \
    abuild \
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
    argon2-dev \
    boost-dev \
    wxwidgets-dev \

ln -s ../lib/wx/config/gtk3-unicode-3.2 /$(xx-info sysroot)usr/bin/wx-config-gtk3

# Fix wxWidgets install for cross-compile.
if xx-info is-cross
then
    # Ignore the --host option passed to wx-config.
    sed -i 's/m_host=${input_option_host/#m_host=${input_option_host/' /$(xx-info sysroot)usr/lib/wx/config/gtk3-unicode-3.2
fi

# Create the meson cross compile file.
echo "[binaries]
pkg-config = '$(xx-info)-pkg-config'
strip = '$(xx-info)-strip'

[properties]
sys_root = '$(xx-info sysroot)'
pkg_config_libdir = [ '$(xx-info sysroot)usr/lib/pkgconfig', '$(xx-info sysroot)usr/share/pkgconfig' ]

[host_machine]
system = 'linux'
cpu_family = '$(xx-info arch)'
cpu = '$(xx-info arch)'
endian = 'little'
" > /tmp/meson-cross.txt

#
# Download sources.
#

log "Downloading FileZilla package..."
mkdir /tmp/filezilla
curl -# -L -f "$FILEZILLA_URL" | tar xJ --strip 1 -C /tmp/filezilla

log "Downloading libfilezilla package..."
mkdir /tmp/libfilezilla
curl -# -L -f "$LIBFILEZILLA_URL" | tar xJ --strip 1 -C /tmp/libfilezilla

log "Downloading fzssh package..."
mkdir /tmp/fzssh
curl -# -L -f "$FZSSH_URL" | tar xJ --strip 1 -C /tmp/fzssh

#
# Compile libfilezilla
#

log "Patching libfilezilla..."
patch -p1 -d /tmp/libfilezilla < "$SCRIPT_DIR"/fix-compilation-libfilezilla.patch

log "Configuring libfilezilla..."
(
    cd /tmp/libfilezilla && \
    ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-doxygen-doc \
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
make DESTDIR=/tmp/filezilla-install -C /tmp/libfilezilla install

#
# Compile fzssh
#

log "Patching fzssh..."
patch -p1 -d /tmp/fzssh < "$SCRIPT_DIR"/fix-compilation-fzssh.patch

log "Configuring fzssh..."
(
    cd /tmp/fzssh && abuild-meson \
        -Db_lto=true \
        --cross-file /tmp/meson-cross.txt \
        . build
)

log "Compiling fzssh..."
meson compile -C /tmp/fzssh/build

log "Installing fzssh..."
DESTDIR=/tmp/filezilla-install meson install --no-rebuild -C /tmp/fzssh/build
DESTDIR=$(xx-info sysroot) meson install --no-rebuild -C /tmp/fzssh/build

#
# Compile FileZilla
#

log "Patching FileZilla..."
patch -p1 -d /tmp/filezilla < "$SCRIPT_DIR"/fix-compilation.patch

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
