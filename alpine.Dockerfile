FROM mhart/alpine-node:12

SHELL ["/usr/bin/env", "sh", "-euxvc"]

RUN apk add --no-cache curl bash openssh-server; \
    # setup openssh server
    echo "root:ChangeM3" | chpasswd; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    mkdir /var/run/sshd; \
    # Setup vscode
    mkdir -p /root/.vscode-server/bin; \
    cd /root/.vscode-server/bin; \
    curl --connect-timeout 7 -L https://update.code.visualstudio.com/commit:8795a9889db74563ddd43eb0a897a2384129a619/server-linux-x64/stable --output vscode-server-linux-x64.tar.gz -w %{http_code}; \
    tar xzf vscode-server-linux-x64.tar.gz; \
    #rm vscode-server-linux-x64.tar.gz vscode-server-linux-x64/node; \
    #ln -s `command -v node` vscode-server-linux-x64/node; \ 
    mv vscode-server-linux-x64 8795a9889db74563ddd43eb0a897a2384129a619

ARG ALPINE_GLIBC_VERSION=2.26-r0

ENV LANG=C.UTF-8

RUN apk add --no-cache --virtual .deps curl ca-certificates; \
    curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub; \
    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$ALPINE_GLIBC_VERSION"; \
    WORKDIR="/tmp"; \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub"; \
    for HEADER in "glibc" "glibc-bin" "glibc-i18n" ; do \
      FILE="${WORKDIR}/${HEADER}.apk" ; \
      curl -Lo $FILE $ALPINE_GLIBC_BASE_URL/$HEADER-$ALPINE_GLIBC_VERSION.apk ; \
      apk add --no-cache $FILE ; \
    done; \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "${LANG}" || :; \
    echo "export LANG=${LANG}" > /etc/profile.d/locale.sh; \
    rm -rf /etc/apk/keys/sgerrand.rsa.pub ${WORKDIR}/*

CMD if [ ! -e /etc/ssh/ssh_host_dsa_key ]; then \
      ssh-keygen -A; \
    fi; \
    /usr/sbin/sshd -D
