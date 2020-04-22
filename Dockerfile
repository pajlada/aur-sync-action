FROM archlinux/base

RUN pacman -Sy && \
    pacman -Sy --noconfirm openssh \
    git fakeroot binutils go-pie   \
    gcc awk binutils coreutils  \
    file gettext grep jq

RUN mkdir -p /root/.ssh && \
    touch /root/.ssh/known_hosts

COPY ssh_config /root/.ssh/config

RUN chmod 600 /root/.ssh/* -R

COPY entrypoint.sh /entrypoint.sh

# USER root
WORKDIR /root

ENTRYPOINT ["/entrypoint.sh"]

