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
1. Attempt to have vscode do a remote debugging, and let it fail. This installed the server in your home directory, that will get patched by the `install` command below
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

1. Where are my files?
  - By default, the `/` directory is mounted in `/host`, so if you are looking for `/a/b/c`, look in `/host/a/b/c`. If you would like to add additional mount directories, simply add to your `local.env` file:

    ```bash
    VSCODE_VOLUMES=('/opt:/opt' '/data1:/data')
    ```

  - This will "mount `/opt` as `/opt` in the container, and `/data1` as `/data` in the container." You can also add other flags like `:ro` to make it read only, if that is what you require.

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
  - It takes a few seconds to create a docker container depending on the kernel, os, and filesystem used. This may exceed the maximum wait time vscode (client) is willing to wait for the server to start. The solution _is_ to try a second time, since the first attempt will have started the server process, and it will still be running for 5 minutes before it auto ends.

1. How?
  - Could you clarify?
    - "Yes"
      - Well, you see the version of `node` and the node native compiled plugins that runs as the `vscode-server` require a modern version of glibc. This is why you can't just replace the `node` executable, it is the plugins that cause the real requirement for modern glibc. The `install` targets replace the `node` command with a shim script that will call the real node executable (`node_exe` after install) inside a container using `just`.
        - `/` is mounted in as `/host`
        - Singularity does its thing, and mounts a lot of things in for you, and set environments variables
        - Docker take similar actions, only manually
          - Mounts in your home dir and tmp
          - Creates a user mimicking your real credentials in the container
          - Changes to the same dir (only if it was already mounted). This limitation has no consequence, since all the commands are run from the home dir, and that is mounted in.
          - Some environment variables may not show up in docker, since it doesn't add everything like singularity does. However, it appears that vscode-server cleanses most of the environment variables when running `node`, so the result should actually be the same. If this is not the case _and_ is a problem, open an issue.