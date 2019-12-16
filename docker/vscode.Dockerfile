FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:vsi as vsi
FROM vsiri/recipe:ep as ep

###############################################################################

FROM centos:7

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN yum install -y ca-certificates; \
    rm -rf /var/cache/yum

COPY --from=tini /usr/local /usr/local
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
RUN chmod u+s /usr/local/bin/gosu
COPY --from=ep /usr/local /usr/local
COPY --from=vsi /vsi /vsi
ADD vscode.env /vscode/
ADD docker/vscode.Justfile /vscode/docker/

ENTRYPOINT ["/usr/local/bin/tini", "--", \
            "/usr/bin/env", "bash", "/vsi/linux/just_entrypoint.sh", \
            "bash", "-c", "~/.vscode-server/bin/${VSCODE_COMMIT}/node_exe \"${@}\"", "node"]

CMD []
