FROM ubuntu:bionic

LABEL maintainer="RLTeam@UPB"
LABEL recommendedtag="rlrules/base:latest"

# sshd
EXPOSE 22/tcp

# install necessary packages
RUN apt-get update && apt-get install -y \
	sudo vim nano curl wget neovim bash-completion \
	ssh telnet rsync ftp \
	net-tools iputils-ping iproute2 traceroute tcpdump dsniff \
	dnsutils \
	&& rm -rf /var/lib/apt/lists/*

# create users and generate passwords
RUN useradd -m student && \
	/bin/bash -c 'echo student:student | chpasswd' && \
	/bin/bash -c 'echo root:student | chpasswd' && \
	usermod --shell /bin/bash student && \
	usermod --shell /bin/bash root && \
	usermod -aG sudo student

COPY files/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

CMD /bin/bash

