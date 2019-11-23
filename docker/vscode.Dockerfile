FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:vsi as vsi

###############################################################################

FROM centos:8

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN yum install -y openssh-server ca-certificates; \
      # Set it up to use sharedkeys, and be happy in singularity
      sed -e '/^ *UsePAM .*/d; \
              /^ *PasswordAuthentication .*/d; \
#               /^ *UsePriviledgeSeparation.*/d; \
              /^ *PubkeyAuthentication .*/d; \
              s|^HostKey /etc/ssh/ssh_host_|HostKey /etc/ssh/keys/ssh_host_|' \
          -e '$aUsePAM no' \
#           -e '$aUsePrivilegeSeparation no' \
          -e '$aPasswordAuthentication no' \
          -e '$aPubkeyAuthentication yes' \
          -i /etc/ssh/sshd_config; \
    mkdir -p /var/run/sshd /etc/ssh/keys; \
    touch /etc/ssh/keys/sshd_config

COPY --from=tini /usr/local /usr/local
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
RUN chmod u+s /usr/local/bin/gosu
COPY --from=vsi /vsi /vsi
ADD docker/80_vscode /usr/local/share/just/root_run_patch/
ADD vscode.env /vscode/
ADD docker/vscode.Justfile /vscode/docker/

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/bin/env", \
            "bash", "/vsi/linux/just_entrypoint.sh"]

CMD ["sshd"]
