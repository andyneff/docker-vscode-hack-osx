FROM centos:latest

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN yum install -y openssh-server ca-certificates; \
    echo "root:ChangeM3" | chpasswd; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    mkdir /var/run/sshd

VOLUME /etc/ssh
EXPOSE 22

RUN echo 'echo "$*" > /tmp/foo.txt; exec /usr/bin/curl "${@}"' > /usr/local/bin/curl; \
    chmod 755 /usr/local/bin/curl

CMD if [ ! -e /etc/ssh/ssh_host_dsa_key ]; then \
      ssh-keygen -A; \
    fi; \
    /usr/sbin/sshd -D
