#!/bin/bash
# Script d'entrée pour le conteneur firewall

set -e

echo "Démarrage du conteneur firewall..."

# Démarrer rsyslog en arrière-plan
echo "Démarrage de rsyslog..."
rsyslogd

# Attendre que rsyslog soit prêt
sleep 2

# Configurer UFW
echo "Configuration de UFW..."
/usr/local/bin/setup-ufw.sh

# Garder le conteneur actif et afficher les logs
echo "Conteneur firewall opérationnel. Logs UFW:"
tail -f /var/log/ufw.log /var/log/syslog 2>/dev/null || sleep infinity



