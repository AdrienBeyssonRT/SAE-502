#!/bin/bash
# Script d'entrée pour le conteneur logcollector

set -e

echo "Démarrage du collecteur de logs..."

# Créer les répertoires nécessaires s'ils n'existent pas
mkdir -p /var/lib/rsyslog
mkdir -p /var/log/firewall
chmod 755 /var/lib/rsyslog
chmod 755 /var/log/firewall

# Vérifier la configuration
echo "Vérification de la configuration rsyslog..."
rsyslogd -N1 || {
    echo "Erreur dans la configuration rsyslog"
    exit 1
}

# Démarrer rsyslog en mode foreground
echo "Démarrage de rsyslog en mode serveur..."
exec rsyslogd -n



