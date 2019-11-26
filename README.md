# docker-vscode-hack-osx
Work-Around and Discussion for https://github.com/microsoft/vscode-remote-release/issues/24

## Preamble

This repository was made to provide files and instructions for implementing the work-around for VSCode Remote-SSH installation on OSX. Currently, an [issue](https://github.com/microsoft/vscode-remote-release/issues/24) exists tracking an official solution.

This fork has been expanded to use `just` and support older linux machines (CentOS 6) and machines not even running docker (singularity).

Please keep all questions regarding this work-around here in this repository so that the official issue is not clogged like a forum thread.

Please create an Issue here to ask your question.  Please check Closed Issues before asking your question.

## Install

1. `. setup.env`
2. `just change password`
3. `just run vscode-server`

## Instructions

### SSH keys

This setup uses SSH keys, so make sure you have them setup both locally and remotely.

Simplified instructions:
1. `ssh-keygen -f ~/.ssh/id_rsa_debug`
1. `scp ~/.ssh/id_rsa_debug.pub remoteserver:~/.ssh/`
1. `ssh remoteserver bash -c 'cat ~/.ssh/id_rsa_debug.pub >> ~/.ssh/authorized_keys`

It doesn't matter if the remote server doesn't allow ssh by ssh key, it will still work for the ssh server we will be setting up in a container.

### Docker on Remote Host

1. Install [Docker](https://hub.docker.com/?overlay=onboarding).
1. Open **Terminal**
1. `git clone --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
1. `cd docker-vscode-hack-osx`
1. `. setup.env`
1. `just up -d`
    - Or `just up` to run in the foreground

### Singularity on Remote Host

Assuming the remote doesn't and can't have docker on it,

1. Local:
    1. `git clone --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
    1. `cd docker-vscode-hack-osx`
    1. `. setup.env`
    1. `just build singular`
1. Remote:
    1. `git clone --recursive https://github.com/andyneff/docker-vscode-hack-osx.git`
1. Local:
    1. `scp vscode_server.simg REMOTE_SERVER:/location/docker-vscode-hack-osx`
1. Remote:
    1. `. setup.env`
    1. `just singular-compose instance start vscode vscode_server`
        - Or `just singular-compose run vscode` to run in the foreground

Method tested with singularity 2.6 and 3.4

### What if the remote server is behind a gateway/firewall?

If exposing a port on the local server does now expose it to you locally, no problem. Just use ssh port forwarding

1. `ssh remoteserver -L 2222:localhost:2222`
2. When filling out the config below, use `localhost` for the `HostName`

### Local Host

Within VSCode:

1. Click Remote Explorer
1. Click Settings
1. Edit .ssh/vscode.config

**vscode.config**
```
Host osx-remote-debug
    HostName IP.AD.DR.ESS
    User user
    Port 2222
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    IdentityFile ~/.ssh/id_rsa_debug
```

The `User` field should have your username on the remote server. In the docker case, it is always `user`. In singularity, it is the username you have outside the container, since singularity copies that in. `IdentityFile` might also be different, depending on how you set it up.

## Caveats

### macos Permissions

In the `docker run` statement above, I am mapping my home directory to `/opt` on the Remote Host.  This may or may not be what you want, depending on your development environment.   If you map to `/opt`, upon first connection, **Docker** will attempt to enumerate all directories and prompt you for access.  If you have mapped to your home directory, Docker may prompt for additional permissions ("Documents", "Desktop", "Downloads", etc) on the remote.

```
"Docker" would like to access files in your Documents folder.
                           [ Don't Allow ]         [ OK ]
```

If you click `[ Don't Allow ]`, you will not be able to remotely see files in that folder.
