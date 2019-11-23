#!/usr/bin/env false bash

function caseify()
{
  local cmd="${1}"
  shift 1
  case "${cmd}" in
    sshd) # Run sshd
      local PRECMD=
      local SSHD_FLAGS=
      if [ -z "${SINGULARITY_NAME+set}" ]; then
        PRECMD="gosu root"
      else
        sed -e '/^ *Port .*/d' \
            -e '$aPort '"${VSCODE_SSHD_PORT}" \
            /etc/ssh/sshd_config > /etc/ssh/keys/sshd_config
        SSHD_FLAGS="-f /etc/ssh/keys/sshd_config"
      fi

      if [ ! -e /etc/ssh/keys/ssh_host_rsa_key ]; then
        ${PRECMD} ssh-keygen -t rsa -f /etc/ssh/keys/ssh_host_rsa_key  -N '' -q
      fi
      if [ ! -e /etc/ssh/keys/ssh_host_ed25519_key ]; then
        ${PRECMD} ssh-keygen -t ed25519 -f /etc/ssh/keys/ssh_host_ed25519_key  -N '' -q
      fi
      if [ ! -e /etc/ssh/keys/ssh_host_ecdsa_key ]; then
        ${PRECMD} ssh-keygen -t ecdsa -f /etc/ssh/keys/ssh_host_ecdsa_key  -N '' -q
      fi

      exec ${PRECMD} /usr/sbin/sshd -D -f /etc/ssh/keys/sshd_config ${SSHD_FLAGS} ${@+"${@}"}
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
