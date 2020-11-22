FROM rlrules/base:latest

LABEL maintainer="RLTeam@UPB"
LABEL recommendedtag="rlrules/lab7:latest"

# apache - lab10
#EXPOSE 80/tcp
#EXPOSE 443/tcp

# vsftpd - lab10
#EXPOSE 20/tcp
#EXPOSE 21/tcp

# telnet
#EXPOSE 23/tcp

# install necessary
RUN apt-get update && apt-get install -y \
		vsftpd apache2 telnet \
	&& rm -rf /var/lib/apt/lists/*

# CMD ["/bin/bash", "-c"]
# ENTRYPOINT [ "echo", "in progress" ]

