# minshell-image
![Docker Repository on Quay](https://quay.io/repository/cloudguardtech/min-shell/status "Docker Repository on Quay")

A minimum Alpine Container Image to work as a sidecar or initialization container for Kubernetes applications.

*Run a command with docker*

    $ docker run --rm cloudguardtech/min-shell ls -al

See `Dockerfile` to determine what has been added to the image.

**NOTE:** The image defaults to USER `app` and GROUP `app` and WORKDIR `/home/app`

