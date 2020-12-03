FROM rlrules/base:latest

LABEL maintainer="RLTeam@UPB"
LABEL recommendedtag="rlrules/lab8:latest"

# install necessary
RUN apt-get update && apt-get install -y \
		vsftpd apache2 telnet telnetd netcat\
	&& rm -rf /var/lib/apt/lists/*


RUN echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student
COPY files/vsftpd.conf /etc/
COPY files/*.sh /usr/local/bin/

# apache 
EXPOSE 80/tcp
EXPOSE 443/tcp
# vsftpd
EXPOSE 20/tcp
EXPOSE 21/tcp
# telnet
EXPOSE 23/tcp

#USER student
CMD ["/sbin/init", "splash"]
#CMD ["/bin/systemd"]
# CMD ["/bin/bash", "-c"]
# ENTRYPOINT [ "echo", "in progress" ]

