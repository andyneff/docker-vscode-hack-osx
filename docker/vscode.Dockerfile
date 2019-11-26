FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:vsi as vsi
FROM vsiri/recipe:ep as ep

###############################################################################

FROM centos:7

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN yum install -y openssh-server ca-certificates; \
    rm -rf /var/cache/yum

      # Set it up to use sharedkeys, and be happy in singularity
RUN ssh_version=($(sshd -? 2>&1 | sed -En 'n; s|^OpenSSH_([0-9]+)\.([0-9]+)([^ ,]*),?.*|\1 \2 \3|; p; q')); \
    sed -e '/^ *UsePAM .*/d' \
        -e '$aUsePAM no' \
        -e '/^ *PasswordAuthentication .*/d' \
        -e '$aPasswordAuthentication no' \
        -e '/^ *PubkeyAuthentication .*/d' \
        -e '$aPubkeyAuthentication yes' \
        -e '/^ *Port .*/d' \
        # This will be expanded by ep, not sshd
        -e '$aPort ${VSCODE_SSHD_PORT}' \
        # -e '/^ *UsePriviledgeSeparation.*/d' \
        # -e '$aUsePrivilegeSeparation no' \
        # -e 's|^HostKey /etc/ssh/ssh_host_|HostKey /etc/ssh/keys/ssh_host_|' \
        -e '/^ *HostKey /d' \
        -e '$aHostKey /etc/ssh/keys/ssh_host_rsa_key' \
        -i /etc/ssh/sshd_config; \
    if [ "${ssh_version[0]}${ssh_version[1]}" -ge "57" ]; then \
      sed -e '$aHostKey /etc/ssh/keys/ssh_host_ecdsa_key' \
          -i /etc/ssh/sshd_config; \
    fi; \
    if [ "${ssh_version[0]}${ssh_version[1]}" -ge "65" ]; then \
      sed -e '$aHostKey /etc/ssh/keys/ssh_host_ed25519_key' \
          -i /etc/ssh/sshd_config; \
    fi; \
    mkdir -p /var/run/sshd /etc/ssh/keys; \
    chmod 644 /etc/ssh/sshd_config

COPY --from=tini /usr/local /usr/local
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
RUN chmod u+s /usr/local/bin/gosu
COPY --from=ep /usr/local /usr/local
COPY --from=vsi /vsi /vsi
ADD vscode.env /vscode/
ADD docker/vscode.Justfile /vscode/docker/

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/bin/env", \
            "bash", "/vsi/linux/just_entrypoint.sh"]

CMD ["sshd"]
