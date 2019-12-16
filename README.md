# docker-vscode-hack-osx
Work-Around and Discussion for https://github.com/microsoft/vscode-remote-release/issues/24

## Preamble

This repository was made to provide files and instructions for implementing the work-around for VSCode Remote-SSH installation on OSX. Currently, an [issue](https://github.com/microsoft/vscode-remote-release/issues/24) exists tracking an official solution.

This fork has been expanded to use `just` and support older linux machines (CentOS 6) and machines not even running docker (singularity).

## Install on remote

### Docker on Remote Host

Everything is done on the remote host

1. `git clone -b simple_singularity --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
1. `cd docker-vscode-hack-osx`
1. `. setup.env`
1. To run images in singularity
  1. `just build singular`
  1. `just install singular`
1. Or to run images in docker (Do not try both, only the first will succeed)
  1. `just build docker`
  1. `just install docker`


### Docker Locally and singularity on Remote Host

Assuming the remote doesn't and can't have docker on it,

1. Local:
    1. `git clone -b simple_singularity --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
    1. `cd docker-vscode-hack-osx`
    1. `. setup.env`
    1. `just build singular`
1. Remote:
    1. `git clone -b simple_singularity --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
1. Local:
    1. `scp vscode_server.simg REMOTE_SERVER:/location/docker-vscode-hack-osx`
1. Remote:
    1. `. setup.env`
    1. `just install`

Tested with singularity 2.6 and 3.4

## FAQ

1. What if I have to put the image in an alternative location?
  - Update your `local.env` on the remote machine with

    ```bash
    vscode_image=alternative_location.simg
    ```

1. What if I want to targe an older version of singularity, like 2.6?
  - Update your `local.env` on the machine with docker to use the appropriate [tag](https://hub.docker.com/repository/docker/vsiri/docker2singularity/tags)

    ```bash
    DOCKER2SINGULARITY_VERSION=v2.6
    ```

1. Why does it sometimes fail on docker, but work the second time?
  - It takes a few seconds to create a docker container depending on the kernel, os, and filesystem used. This may exceed the maximum wait time vscode (client) is willing to wait for the server to start. The solution _is_ to try a second time, since the first attempt will have started the server process, and it will still be running for a few minutes.
