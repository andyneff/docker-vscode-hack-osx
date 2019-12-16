#!/usr/bin/env bash

source "${VSI_COMMON_DIR}/linux/just_env" "$(dirname "${BASH_SOURCE[0]}")"/'vscode.env'
# Plugins
source "${VSI_COMMON_DIR}/linux/docker_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_docker_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_git_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_singularity_functions.bsh"

cd "${VSCODE_CWD}"

# Main function
function caseify()
{
  local just_arg=$1
  shift 1
  case ${just_arg} in
    build) # Build Docker image
      if [ "$#" -gt "0" ]; then
        Docker-compose "${just_arg}" ${@+"${@}"}
        extra_args=$#
      else
        justify build recipes-auto "${VSCODE_CWD}/docker"/*.Dockerfile
        Docker-compose build
      fi
      ;;
    build_singular) # Build singularity images for terra dsm
      justify build
      (
        . ${VSCODE_SINGULAR_COMPOSE_FILES}
        export SINGULARITY_CUSTOM_IMPORT_SCRIPT="${VSCODE_CWD}/docker/tosingular"

        for instance in ${instances[@]+"${instances[@]}"}; do
          docker_image="${instance}_docker_image"
          # Singularity specific hacks for Centos 6 which has no overlayfs support
          justify singular-compose import "${instance}" "${!docker_image}"
        done
      )
      ;;

    run_singular) # Run nodejs in singularity
      SINGULARITY_EXEC=1 justify singular-compose run vscode ${@+"${@}"}
      ;;

    install) # Install
      local commit
      for commit in ~/.vscode-server/bin/*; do
        if [ ! -x "${commit}/node_exe" ]; then
          mv "${commit}/node" "${commit}/node_exe"
          echo '#!/usr/bin/env bash' > "${commit}/node"
          echo "source \"${VSCODE_CWD}/setup.env\"" >> "${commit}/node"
          echo 'just run singular "${@}"' >> "${commit}/node"
          chmod 755 "${commit}/node"
          echo "Installed in ${commit}" >&2
        else
          echo "Already installed in ${commit}" >&2
        fi
      done
      ;;

    run_vscode-server) # Run vscode server
      Just-docker-compose run --service-ports vscode ${@+"${@}"}
      extra_args=$#
      ;;
    shell) # Run vscode server shell (for debugging)
      Just-docker-compose run vscode bash ${@+"${@}"}
      extra_args=$#
      ;;

    sync) # Synchronize the many aspects of the project when new code changes \
          # are applied e.g. after "git checkout"
      if [ ! -e "${VSCODE_CWD}/.just_synced" ]; then
        # Add any commands here, like initializing a database, etc... that need
        # to be run the first time sync is run.
        touch "${VSCODE_CWD}/.just_synced"
      fi
      # Add any extra steps run when syncing everytime
      Docker-compose down
      justify git_submodule-update # For those users who don't remember!
      justify build
      ;;
    *)
      defaultify "${just_arg}" ${@+"${@}"}
      ;;
  esac
}

if ! command -v justify &> /dev/null; then caseify ${@+"${@}"};fi
