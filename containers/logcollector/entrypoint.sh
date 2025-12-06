#!/bin/bash
# Script d'entrée pour le conteneur logcollector

set -e

echo "Démarrage du collecteur de logs..."

# Vérifier la configuration
echo "Vérification de la configuration rsyslog..."
rsyslogd -N1

# Démarrer rsyslog
echo "Démarrage de rsyslog en mode serveur..."
rsyslogd -n



