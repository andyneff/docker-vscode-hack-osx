FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:vsi as vsi

###############################################################################

FROM centos:8

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN yum install -y openssh-server ca-certificates; \
    echo "root:ChangeM3" | chpasswd; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    mkdir /var/run/sshd

COPY --from=tini /usr/local /usr/local
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
RUN chmod u+s /usr/local/bin/gosu
COPY --from=vsi /vsi /vsi
ADD docker/80_vscode.patch /usr/local/share/just/root_run_patch/
ADD vscode.env /vscode/
ADD docker/vscode.Justfile /vscode/docker/

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/bin/env", \
            "bash", "/vsi/linux/just_entrypoint.sh"]

CMD ["sshd"]
