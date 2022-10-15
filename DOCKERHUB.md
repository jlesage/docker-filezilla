# Docker container for FileZilla
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/filezilla/latest)](https://hub.docker.com/r/jlesage/filezilla/tags) [![Build Status](https://github.com/jlesage/docker-filezilla/actions/workflows/build-image.yml/badge.svg?branch=master)](https://github.com/jlesage/docker-filezilla/actions/workflows/build-image.yml) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-filezilla.svg)](https://github.com/jlesage/docker-filezilla/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage)

This is a Docker container for [FileZilla](https://filezilla-project.org).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

---

[![FileZilla logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/filezilla-icon.png&w=200)](https://filezilla-project.org)[![FileZilla](https://images.placeholders.dev/?width=288&height=110&fontFamily=Georgia,sans-serif&fontWeight=400&fontSize=52&text=FileZilla&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://filezilla-project.org)

FileZilla is a cross-platform graphical FTP, SFTP, and FTPS file
management tool with a vast list of features.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the FileZilla docker container with the following command:
```shell
docker run -d \
    --name=filezilla \
    -p 5800:5800 \
    -v /docker/appdata/filezilla:/config:rw \
    -v $HOME:/storage:rw \
    jlesage/filezilla
```

Where:
  - `/docker/appdata/filezilla`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible to the application.

Browse to `http://your-host-ip:5800` to access the FileZilla GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-filezilla.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-filezilla/issues
