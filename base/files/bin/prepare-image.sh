#!/bin/bash
# Prepares the Docker image (runs at build time)
set -e

# enable systemd services
systemctl enable container-boot
systemctl enable networking
systemctl enable ssh
systemctl enable vsftpd
systemctl enable openbsd-inetd

# configure ifupdown networking (not required anymore for ifupdown-ng)
# sed -i -E -e 's/^#?CONFIGURE_INTERFACES=.*/CONFIGURE_INTERFACES=yes/' /etc/default/networking
# sed -i -E -e 's/^#?WAIT_ONLINE_TIMEOUT=.*/WAIT_ONLINE_TIMEOUT=10/' /etc/default/networking

# create student user
useradd -m student
/bin/bash -c 'echo student:student | chpasswd'
/bin/bash -c 'echo root:student | chpasswd'
usermod --shell /bin/bash student
usermod --shell /bin/bash root
usermod -aG sudo student
echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student

# customize user home & bashrc
rsync --chown=student:student /home/.container-tweaks/bashrc /home/student/.bashrc
rsync --chown=root:root /home/.container-tweaks/bashrc /root/.bashrc

echo "export PS1=\"\${RL_PS1_FORMAT}\"" >> /root/.bashrc
echo "export PS1=\"\${RL_PS1_FORMAT}\"" >> /home/student/.bashrc

rm -f "${BASH_SOURCE[0]}"

