#!/bin/bash
# Script pour forcer la génération de logs UFW avec de vraies connexions TCP

FIREWALL_IP="firewall"
echo "=== Génération de logs UFW avec connexions TCP réelles ==="
echo ""

# Générer plusieurs tentatives sur différents ports bloqués
for port in 445 3389 139 80; do
    echo "Test port $port (devrait être BLOQUÉ)..."
    for i in {1..3}; do
        timeout 1 bash -c "</dev/tcp/$FIREWALL_IP/$port" 2>&1 || true
        sleep 0.5
    done
    sleep 1
done

# Test port 22 (devrait être autorisé depuis réseau interne)
echo ""
echo "Test port 22 (devrait être AUTORISÉ depuis réseau interne)..."
timeout 2 bash -c "</dev/tcp/$FIREWALL_IP/22" 2>&1 || true

echo ""
echo "=== Tests terminés ==="
echo ""
echo "Attendez 3-5 secondes puis vérifiez:"
echo "  1. Logs dans le firewall: docker exec firewall tail -30 /var/log/kern.log | grep -i ufw"
echo "  2. Logs dans le collecteur: docker exec logcollector tail -20 /var/log/firewall/*.log | grep -i ufw"
echo "  3. Interface web: http://localhost:5000"


