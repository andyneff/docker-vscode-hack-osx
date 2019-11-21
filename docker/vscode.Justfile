#!/usr/bin/env false bash

function caseify()
{
  local cmd="${1}"
  shift 1
  case "${cmd}" in
# default CMD
    vscode-cmd) # Run example
      echo "Run vscode here: ${cmd} ${@+${@}}"
      extra_args=$#
      ;;

    *) # Default: Run command
      exec "${cmd}" ${@+"${@}"}
      ;;
  esac
}
