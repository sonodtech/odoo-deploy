FROM alpine:latest

# Install dependencies
RUN set -x \
  && apk add --no-cache \
    ansible \
    openssh-client \
    rsync


RUN adduser -D -s /bin/sh gitlab-runner -g ""

# Set up SSH directory and permissions for gitlab-runner
RUN mkdir -p /home/gitlab-runner/.ssh \
    && touch /home/gitlab-runner/.ssh/known_hosts \
    && chmod 700 /home/gitlab-runner/.ssh \
    && chmod 600 /home/gitlab-runner/.ssh/known_hosts \
    && chown -R gitlab-runner:gitlab-runner /home/gitlab-runner/.ssh

# Switch to gitlab-runner user
USER gitlab-runner

# Set working directory
WORKDIR /ansible

# Copy configuration and playbooks
COPY --chown=gitlab-runner --chmod=644 ssh_config /home/gitlab-runner/.ssh/config
COPY --chown=root --chmod=644 ansible.cfg /etc/ansible/ansible.cfg
COPY --chown=gitlab-runner tasks /ansible/tasks
COPY --chown=gitlab-runner deploy.yml /ansible

# Install Ansible Galaxy roles
RUN /usr/bin/ansible-galaxy install ansistrano.deploy ansistrano.rollback