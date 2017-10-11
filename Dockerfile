#
# filezilla Dockerfile
#
# https://github.com/jlesage/docker-filezilla
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v3.0.2

# Define software versions.
ARG WXWIDGETS_VERSION=3.0.3
ARG LIBFILEZILLA_VERSION=0.11.0
ARG FILEZILLA_VERSION=3.28.0
ARG VIM_VERSION=8.0.0830

# Define software download URLs.
ARG WXWIDGETS_URL=https://github.com/wxWidgets/wxWidgets/releases/download/v${WXWIDGETS_VERSION}/wxWidgets-${WXWIDGETS_VERSION}.tar.bz2
ARG LIBFILEZILLA_URL=http://download.filezilla-project.org/libfilezilla/libfilezilla-${LIBFILEZILLA_VERSION}.tar.bz2
ARG FILEZILLA_URL=https://sourceforge.net/projects/filezilla/files/FileZilla_Client/${FILEZILLA_VERSION}/FileZilla_${FILEZILLA_VERSION}_src.tar.bz2
ARG VIM_URL=https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

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
    rm -rf /tmp/* /tmp/.[!.]*

# Compile FileZilla.
# NOTE: FileZilla is affected by a wxWidgets bug fixed by the following commit:
#       https://github.com/wxWidgets/wxWidgets/commit/ce1dce1.
#       This fix is not yet included in an official release.  Thus, wxWidgets
#       needs to be manually patched and compiled until a new version is
#       released.
RUN \
    # Install build dependencies.
    add-pkg --virtual build-dependencies-common \
        curl \
        file \
        patch \
        build-base \
        && \
    add-pkg --virtual build-dependencies-wxwidgets \
        gtk+2.0-dev \
        mesa-dev \
        zlib-dev \
        tiff-dev \
        libjpeg-turbo-dev \
        expat-dev \
	libsm-dev \
        glu-dev \
        sdl-dev \
        gst-plugins-base0.10-dev \
	gstreamer0.10-dev \
        gconf-dev \
        && \
    add-pkg --virtual build-dependencies-filezilla \
        libidn-dev \
        nettle-dev \
        gnutls-dev \
        sqlite-dev \
        xdg-utils \
        && \
    # Download sources.
    echo "Downloading sources..." && \
    curl -# -L ${WXWIDGETS_URL} | tar xj && \
    curl -# -L ${FILEZILLA_URL} | tar xj && \
    # Compile wxWidgets.
    cd wxWidgets-${WXWIDGETS_VERSION} && \
    curl -# -L -o assert.patch https://github.com/wxWidgets/wxWidgets/commit/ce1dce113c5eda42f49ba3278bb21c61872ca37d.patch && \
    patch -p1 < assert.patch && \
    ./configure \
        --prefix=/usr \
        --with-sdl \
        --with-opengl \
        --enable-unicode \
        --enable-aui \
        --enable-no_deps \
        --enable-shared \
        --enable-sound \
        --enable-mediactrl \
        --disable-rpath \
        --disable-optimise \
        && \
    make install && \
    cd .. && \
    # Compile FileZilla.
    cd filezilla-${FILEZILLA_VERSION} && \
    # Patch source code: open local files without extension with the same logic
    # as remote ones.  This way, user's settings are used, which allow us to
    # use a default editor for all files.
    sed-patch 's/wxString cmd = GetSystemOpenCommand(fn.GetFullPath(), program_exists);/wxString cmd = pEditHandler->GetOpenCommand(fn.GetFullPath(), program_exists);/' src/interface/LocalListView.cpp && \
    ./configure \
        --prefix=/usr \
        --with-pugixml=builtin \
        --without-dbus \
        --disable-autoupdatecheck && \
    make install && \
    rm /usr/share/applications/filezilla.desktop && \
    rm -r /usr/share/applications && \
    cd .. && \
    # Remove wxWidgets stuff that we no longer need.
    rm -r /usr/include \
          /usr/lib/wx/config \
          /usr/bin/wxrc* \
          /usr/share/bakefile \
          /usr/lib/libwx_gtk2u_media-*.so.* \
          && \
    # Cleanup.
    del-pkg \
         build-dependencies-common \
         build-dependencies-wxwidgets \
         build-dependencies-filezilla \
        && \
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
        ttf-dejavu

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
