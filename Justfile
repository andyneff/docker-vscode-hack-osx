#!/usr/bin/env bash

source "${VSI_COMMON_DIR}/linux/just_env" "$(dirname "${BASH_SOURCE[0]}")"/'vscode.env'
# Plugins
source "${VSI_COMMON_DIR}/linux/docker_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_docker_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_git_functions.bsh"
source "${VSI_COMMON_DIR}/linux/just_singularity_functions.bsh"

export CWD="$(pwd)"
cd "${VSCODE_CWD}"

# Main function
function caseify()
{
  local just_arg=$1
  shift 1
  case ${just_arg} in
    build_docker) # Build Docker image
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

        for instance in ${instances[@]+"${instances[@]}"}; do
          docker_image="${instance}_docker_image"
          justify singular-compose import "${instance}" "${!docker_image}"
        done
      )
      ;;

    run_singular) # Run nodejs in singularity
      SINGULARITY_EXEC=1 justify singular-compose run vscode ${@+"${@}"}
      ;;
    shell_singular) # Run shell in singularity
      SINGULARITY_EXEC=1 justify singular-compose shell vscode ${@+"${@}"}
      ;;

    # install_singular) # Install for running in as singularity container
    # install_docker) # Install for running in a docker container
    install_*)
      local platform="${just_arg#*_}"
      local commit
      for commit in ~/.vscode-server/bin/*; do
        if [ ! -x "${commit}/node_exe" ]; then
          mv "${commit}/node" "${commit}/node_exe"
          echo '#!/usr/bin/env bash' > "${commit}/node"
          echo "source \"${VSCODE_CWD}/setup.env\"" >> "${commit}/node"
          echo "export JUSTFILE=\"${VSCODE_CWD}/Justfile\"" >> "${commit}/node"
          # echo 'echo "${@}" >> /tmp/node_debug.txt' >> "${commit}/node"
          echo "exec just run ${platform} "'"${BASH_SOURCE[0]}" "${@}"' >> "${commit}/node"
          chmod 755 "${commit}/node"
          echo "Installed in ${commit}" >&2
        else
          echo "Already installed in ${commit}" >&2
        fi
      done
      ;;

    uninstall) # Uninstall
      local commit
      for commit in ~/.vscode-server/bin/*; do
        if [ -x "${commit}/node_exe" ]; then
          rm "${commit}/node"
          mv "${commit}/node_exe" "${commit}/node"
          echo "Uninstalled in ${commit}" >&2
        else
          echo "Already uninstalled in ${commit}" >&2
        fi
      done
      ;;

    run_docker) # Run vscode server
      Just-docker-compose run vscode ${@+"${@}"}
      extra_args=$#
      ;;
    shell_docker) # Run vscode server shell (for debugging)
      Just-docker-compose run --entrypoint="bash /vsi/linux/just_entrypoint.sh" vscode bash ${@+"${@}"}
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
