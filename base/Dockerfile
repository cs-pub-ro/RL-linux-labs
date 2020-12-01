FROM ubuntu:bionic

LABEL maintainer="RLTeam@UPB"
LABEL recommendedtag="rlrules/base:latest"

# required for systemd
ENV container docker
STOPSIGNAL SIGRTMIN+3

# sshd
EXPOSE 22/tcp

# install necessary packages
RUN apt-get update && apt-get install -y \
	sudo vim dbus nano curl wget neovim bash-completion \
	systemd ifupdown ssh telnet rsync ftp \
	net-tools iputils-ping iproute2 traceroute tcpdump dsniff \
	dnsutils netcat vsftpd apache2 telnetd \
	&& rm -rf /var/lib/apt/lists/*

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
RUN chmod +x /usr/local/bin/*.sh && /usr/local/bin/prepare-image.sh

CMD ["/lib/systemd/systemd"]

