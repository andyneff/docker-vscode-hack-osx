#!/usr/bin/env false bash

function caseify()
{
  local cmd="${1}"
  shift 1
  case "${cmd}" in
    sshd) # Run sshd
      if [ ! -e /etc/ssh/ssh_host_dsa_key ]; then
        gosu root ssh-keygen -A
      fi
      exec gosu root /usr/sbin/sshd -D ${@+"${@}"}
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
