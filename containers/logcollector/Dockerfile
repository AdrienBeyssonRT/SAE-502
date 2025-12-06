FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y rsyslog net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configuration rsyslog serveur
COPY rsyslog.conf /etc/rsyslog.conf

# Créer les répertoires nécessaires
RUN mkdir -p /var/log/firewall && \
    mkdir -p /var/lib/rsyslog && \
    chmod 755 /var/log/firewall && \
    chmod 755 /var/lib/rsyslog

# Exposer le port UDP 514
EXPOSE 514/udp

# Script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]



