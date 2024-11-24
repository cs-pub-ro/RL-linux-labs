FROM ubuntu:22.04

# required for systemd
ENV container docker
ENV TERM xterm-256color
STOPSIGNAL SIGRTMIN+3

# sshd
EXPOSE 22/tcp

# install necessary packages
RUN apt-get update && apt-get install -y \
	sudo locales vim dbus nano curl wget neovim bash-completion \
	systemd udev ifupdown-ng ssh telnet rsync ftp \
	net-tools iputils-ping iproute2 traceroute tcpdump dsniff \
	dnsutils netcat vsftpd apache2 telnetd \
	&& rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Systemd: disable optional services
RUN find /etc/systemd/system \
	/lib/systemd/system \
	-path '*.wants/*' \
	-not -name '*journald*' \
	-not -name '*systemd-tmpfiles*' \
	-not -name '*systemd-user-sessions*' \
	-exec rm \{} \; && \
	systemctl set-default multi-user.target

# create users and generate passwords
COPY files/bin/ /usr/local/bin/
COPY files/etc/ /etc/
COPY files/home/ /home/.container-tweaks/
RUN chmod +x /usr/local/bin/*.sh && /usr/local/bin/prepare-image.sh

CMD ["/lib/systemd/systemd"]

