#
# filezilla Dockerfile
#
# https://github.com/jlesage/docker-filezilla
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v2.0.3

# Define software versions.
ARG LIBFILEZILLA_VERSION=0.10.0
ARG FILEZILLA_VERSION=3.27.0.1

# Define software download URLs.
ARG LIBFILEZILLA_URL=http://download.filezilla-project.org/libfilezilla/libfilezilla-${LIBFILEZILLA_VERSION}.tar.bz2
ARG FILEZILLA_URL=https://sourceforge.net/projects/filezilla/files/FileZilla_Client/${FILEZILLA_VERSION}/FileZilla_${FILEZILLA_VERSION}_src.tar.bz2

# Define working directory.
WORKDIR /tmp

# Add required repositories.
RUN \
    echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Compile libfilezilla.
RUN \
    # Install build dependencies.
    add-pkg --virtual build-dependencies \
        curl \
        file \
        build-base \
        && \
    # Download sources.
    curl -# -L ${LIBFILEZILLA_URL} | tar xj && \
    # Compile.
    cd libfilezilla-${LIBFILEZILLA_VERSION} && \
    ./configure && \
    make install && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/*

# Compile FileZilla.
RUN \
    # Install build dependencies.
    add-pkg --virtual build-dependencies \
        curl \
        file \
        build-base \
        libidn-dev \
        nettle-dev \
        gnutls-dev \
        sqlite-dev \
        xdg-utils \
        && \
    add-pkg pugixml-dev@testing wxgtk-dev@community && \
    # Download sources.
    echo "Downloading FileZilla package..." && \
    curl -# -L ${FILEZILLA_URL} | tar xj && \
    # Compile.
    cd filezilla-${FILEZILLA_VERSION} && \
    ./configure \
        --without-dbus \
        --disable-autoupdatecheck && \
    make install && \
    rm /usr/local/share/applications/filezilla.desktop && \
    rm -r /usr/local/share/applications && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies \
        pugixml-dev \
        wxgtk-dev && \
    rm -rf /tmp/*

# Install dependencies.
RUN \
    add-pkg \
        gtk+2.0 \
        libidn \
        sdl \
        sqlite-libs \
        pugixml@testing \
        wxgtk@community \
        ttf-dejavu

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
