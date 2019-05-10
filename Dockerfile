#
# filezilla Dockerfile
#
# https://github.com/jlesage/docker-filezilla
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.2

# Define software versions.
ARG LIBFILEZILLA_VERSION=0.16.0
ARG FILEZILLA_VERSION=3.42.1
ARG VIM_VERSION=8.0.0830

# Define software download URLs.
ARG LIBFILEZILLA_URL=https://download.filezilla-project.org/libfilezilla/libfilezilla-${LIBFILEZILLA_VERSION}.tar.bz2
ARG FILEZILLA_URL=https://download.filezilla-project.org/client/FileZilla_${FILEZILLA_VERSION}_src.tar.bz2
ARG VIM_URL=https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Compile FileZilla.
RUN \
    # Install build dependencies.
    add-pkg --virtual build-dependencies \
        curl \
        file \
        patch \
        build-base \
        libidn-dev \
        nettle-dev \
        gnutls-dev \
        sqlite-dev \
        xdg-utils \
        wxgtk-dev \
        && \
    # Download sources.
    echo "Downloading sources..." && \
    curl -# -L ${LIBFILEZILLA_URL} | tar xj && \
    curl -# -L ${FILEZILLA_URL} | tar xj && \
    # Compile libfilezilla.
    cd libfilezilla-${LIBFILEZILLA_VERSION} && \
    ./configure \
        --prefix=/tmp/libfilezilla_install \
        --enable-shared=no \
        && \
    make install && \
    cd .. && \
    # Compile FileZilla.
    cd filezilla-${FILEZILLA_VERSION} && \
    # Patch source code: open local files without extension with the same logic
    # as remote ones.  This way, user's settings are used, which allow us to
    # use a default editor for all files.
    sed-patch 's/wxString cmd = GetSystemOpenCommand(fn.GetFullPath(), program_exists);/wxString cmd = pEditHandler->GetOpenCommand(fn.GetFullPath(), program_exists);/' src/interface/LocalListView.cpp && \
    env PKG_CONFIG_PATH=/tmp/libfilezilla_install/lib/pkgconfig ./configure \
        --prefix=/usr \
        --with-pugixml=builtin \
        --without-dbus \
        --disable-autoupdatecheck \
        --disable-manualupdatecheck \
        && \
    make install && \
    strip /usr/bin/filezilla && \
    rm /usr/share/applications/filezilla.desktop && \
    rm -r /usr/share/applications && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Compile VIM.
RUN \
    # Install build dependencies.
    add-pkg --virtual build-dependencies \
        curl \
        build-base \
        ncurses-dev \
        libxt-dev \
        gtk+2.0-dev && \
    # Download sources.
    curl -# -L ${VIM_URL} | tar xz && \
    # Compile.
    cd vim-${VIM_VERSION} && \
    ./configure \
        --prefix=/usr \
        --enable-gui=gtk2 \
        --disable-nls \
        --enable-multibyte \
        --localedir=/tmp/vim-local \
        --mandir=/tmp/vim-man \
        --docdir=/tmp/vim-doc \
        && \
    echo '#define SYS_VIMRC_FILE "/etc/vim/vimrc"' >> src/feature.h && \
    echo '#define SYS_GVIMRC_FILE "/etc/vim/gvimrc"' >> src/feature.h && \
    cd src && \
    make && \
    make installvimbin && \
    make installrtbase && \
    cd .. && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    add-pkg \
        # The following package is used to send key presses to the X process.
        xdotool \
        # The following package is needed by VIM.
        ncurses \
        # The following packages are needed by FileZilla.
        gtk+2.0 \
        libidn \
        sdl \
        sqlite-libs \
        ttf-dejavu \
        wxgtk \
        # GTK theme.
        adwaita-gtk2-theme

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="FileZilla">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="FileZilla">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/filezilla-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="FileZilla"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="filezilla" \
      org.label-schema.description="Docker container for FileZilla" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-filezilla" \
      org.label-schema.schema-version="1.0"
