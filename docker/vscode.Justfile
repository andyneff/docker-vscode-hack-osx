#!/usr/bin/env false bash

function caseify()
{
  local cmd="${1}"
  shift 1
  case "${cmd}" in
    sshd) # Run sshd
      if [ -L ~/.ssh ]; then
        rm ~/.ssh
      fi
      ln -sf /.user_ssh ~/.ssh
      ep -d /etc/ssh/sshd_config 2>/dev/null > /etc/ssh/keys/sshd_config

      ssh_version=($(sshd -? 2>&1 | sed -En 'n; s|^OpenSSH_([0-9]+)\.([0-9]+)([^ ,]*),?.*|\1 \2 \3|; p; q'))
      if [ ! -e /etc/ssh/keys/ssh_host_rsa_key ]; then
        ssh-keygen -t rsa -f /etc/ssh/keys/ssh_host_rsa_key  -N '' -q
      fi

      if [ "${ssh_version[0]}${ssh_version[1]}" -ge "57" ] && \
         [ ! -e /etc/ssh/keys/ssh_host_ecdsa_key ]; then
        # Open ssh 5.7+
        ssh-keygen -t ecdsa -f /etc/ssh/keys/ssh_host_ecdsa_key  -N '' -q
      fi
      if [ "${ssh_version[0]}${ssh_version[1]}" -ge "65" ] && \
         [ ! -e /etc/ssh/keys/ssh_host_ed25519_key ]; then
        # Open ssh 6.5+
        ssh-keygen -t ed25519 -f /etc/ssh/keys/ssh_host_ed25519_key  -N '' -q
      fi

      set -x
      exec /usr/sbin/sshd -D -f /etc/ssh/keys/sshd_config ${@+"${@}"}
      ;;

    password)
      gosu root bash -c \
      '
        read -s -p "New root password: " pw
        pw="root:${pw}"
        chpasswd <<< "${pw}" # <== Does not expose password to envvar or cmdline (/proc)
        cp /etc/passwd /var/passwd/passwd
        cp /etc/shadow /var/passwd/shadow
      '
      echo
      ;;

    *) # Default: Run command
      exec "${cmd}" ${@+"${@}"}
      ;;
  esac
}
