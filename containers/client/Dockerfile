FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y nmap curl netcat-openbsd iputils-ping telnet dnsutils net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Scripts de test
COPY test_scripts /usr/local/bin/
COPY generate-traffic.sh /usr/local/bin/generate-traffic.sh
COPY test-rules-ufw.sh /usr/local/bin/test-rules-ufw.sh
COPY force-ufw-logs.sh /usr/local/bin/force-ufw-logs.sh
RUN chmod +x /usr/local/bin/*.sh

WORKDIR /root

# Script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]





