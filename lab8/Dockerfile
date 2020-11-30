FROM rlrules/base:latest

LABEL maintainer="RLTeam@UPB"
LABEL recommendedtag="rlrules/lab8:latest"

# install necessary
RUN apt-get update && apt-get install -y \
		vsftpd apache2 telnet netcat\
	&& rm -rf /var/lib/apt/lists/*


RUN echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student
# apache 
EXPOSE 80/tcp
EXPOSE 443/tcp

# vsftpd
EXPOSE 20/tcp
EXPOSE 21/tcp

# telnet
EXPOSE 23/tcp

USER student

# CMD ["/bin/bash", "-c"]
# ENTRYPOINT [ "echo", "in progress" ]

