#
# filezilla Dockerfile
#
# https://github.com/jlesage/docker-filezilla
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG LIBFILEZILLA_VERSION=0.49.0
ARG FILEZILLA_VERSION=3.68.1

# Define software download URLs.
ARG LIBFILEZILLA_URL=https://download.filezilla-project.org/libfilezilla/libfilezilla-${LIBFILEZILLA_VERSION}.tar.xz
ARG FILEZILLA_URL=https://download.filezilla-project.org/client/FileZilla_${FILEZILLA_VERSION}_src.tar.xz

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build FileZilla.
FROM --platform=$BUILDPLATFORM alpine:3.17 AS filezilla
ARG TARGETPLATFORM
ARG FILEZILLA_VERSION
ARG LIBFILEZILLA_VERSION
COPY --from=xx / /
COPY src/filezilla /build
RUN /build/build.sh "$FILEZILLA_VERSION" "$LIBFILEZILLA_VERSION"
RUN xx-verify \
    /tmp/filezilla-install/usr/bin/filezilla

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.17-v4.6.7

ARG FILEZILLA_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        wxwidgets-gtk3 \
        libidn \
        sqlite-libs \
        # Need a font.
        ttf-dejavu \
        # The following package is used to send key presses to close FileZilla.
        xdotool \
        # Vim editor.
        gvim

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/filezilla-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=filezilla /tmp/filezilla-install/usr/bin /usr/bin
COPY --from=filezilla /tmp/filezilla-install/usr/share/filezilla /usr/share/filezilla
COPY --from=filezilla /tmp/filezilla-install/usr/share/icons /usr/share/icons
COPY --from=filezilla /tmp/filezilla-install/usr/share/locale /usr/share/locale

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "FileZilla" && \
    set-cont-env APP_VERSION "$FILEZILLA_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="filezilla" \
      org.label-schema.description="Docker container for FileZilla" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-filezilla" \
      org.label-schema.schema-version="1.0"
