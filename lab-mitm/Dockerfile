FROM rlrules/base:latest

# nothing to do
RUN export DEBIAN_FRONTEND=noninteractive; \
	apt-get update && apt-get install -y \
		elinks python3 python3-pip pipx && \
	pipx install --global slowloris

RUN systemctl enable apache2

