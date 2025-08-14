FROM alpine:latest

RUN set -x \
  && apk add --no-cache \
    ansible \
    openssh-client \
    rsync

COPY --chown=root --chmod=644 ansible.cfg /etc/ansible/ansible.cfg

RUN adduser -D -s /bin/sh gitlab-runner -g ""
USER gitlab-runner

WORKDIR /ansible

COPY --chown=gitlab-runner --chmod=644 ssh_config /home/gitlab-runner/.ssh/config
COPY --chown=gitlab-runner tasks /ansible/tasks
COPY --chown=gitlab-runner deploy.yml /ansible

RUN  /usr/bin/ansible-galaxy install ansistrano.deploy ansistrano.rollback
