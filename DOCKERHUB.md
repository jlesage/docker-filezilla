# Docker container for FileZilla
[![Release](https://img.shields.io/github/release/jlesage/docker-filezilla.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-filezilla/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/filezilla/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/filezilla/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/filezilla?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/filezilla)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/filezilla?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/filezilla)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-filezilla/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-filezilla/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-filezilla)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This project provides a lightweight and secure Docker container for
[FileZilla](https://filezilla-project.org).

Access the application's full graphical interface directly from any modern web
browser - no downloads, installs, or setup required on the client side - or
connect with any VNC client.

The web interface also offers audio playback, seamless clipboard sharing, an
integrated file manager and terminal for accessing the container's files and
shell, desktop notifications, and more.

> This Docker container is entirely unofficial and not made by the creators of
> FileZilla.

---

[![FileZilla logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/filezilla-icon.png&w=110)](https://filezilla-project.org)[![FileZilla](https://images.placeholders.dev/?width=288&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=FileZilla&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://filezilla-project.org)

FileZilla is a cross-platform graphical FTP, SFTP, and FTPS file
management tool with a vast list of features.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the FileZilla docker container with the following command:
```shell
docker run -d \
    --name=filezilla \
    -p 5800:5800 \
    -v /docker/appdata/filezilla:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/filezilla
```

Where:

  - `/docker/appdata/filezilla`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the FileZilla GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-filezilla.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-filezilla/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
