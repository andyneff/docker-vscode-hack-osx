FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:vsi as vsi

###############################################################################

FROM debian:stretch
SHELL ["/usr/bin/env", "bash", "-euxvc"]

# Install any runtime dependencies
RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tzdata; \
    rm -r /var/lib/apt/lists/*

# Install any additional packages
RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      # Example of a package
      qbs-examples; \
    rm -rf /var/lib/apt/lists/*

# Another typical example of installing a package
# RUN build_deps="wget ca-certificates"; \
#     apt-get update; \
#     DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${build_deps}; \
#     wget -q https://www.vsi-ri.com/bin/deviceQuery; \
#     DEBIAN_FRONTEND=noninteractive apt-get purge -y --autoremove ${build_deps}; \
#     rm -rf /var/lib/apt/lists/*

COPY --from=tini /usr/local/bin/tini /usr/local/bin/tini

COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
# Allow non-privileged to run gosu (remove this to take root away from user)
RUN chmod u+s /usr/local/bin/gosu

COPY --from=vsi /vsi /vsi
ADD ["", "/src/"]
ADD docker/vscode.Justfile /src/docker/

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/bin/env", "bash", "/vsi/linux/just_entrypoint.sh"]
# Does not require execute permissions, unlike:
# ENTRYPOINT ["/usr/local/bin/tini", "--", "/vsi/linux/just_entrypoint.sh"]

CMD ["vscode-cmd"]
