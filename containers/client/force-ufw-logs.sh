#!/bin/bash
# Script optimisé pour générer des logs UFW avec de vraies connexions TCP
# Utilisé par le playbook deploy-and-test.yml
#
# Usage: force-ufw-logs.sh [FIREWALL_IP] [ITERATIONS]
#   FIREWALL_IP: IP ou hostname du firewall (défaut: firewall)
#   ITERATIONS: Nombre de tentatives par port (défaut: 5)

set -euo pipefail

FIREWALL_IP="${1:-firewall}"
ITERATIONS="${2:-5}"

echo "=== Génération de logs UFW avec connexions TCP réelles ==="
echo "Firewall: $FIREWALL_IP"
echo "Itérations par port: $ITERATIONS"
echo ""

# Ports bloqués selon les règles UFW (setup-ufw.sh)
# - 445 (SMB)
# - 3389 (RDP)
# - 139 (NetBIOS Session)
# - 137/138 (NetBIOS Name/Datagram) - UDP, donc testé avec TCP pour générer des logs
BLOCKED_PORTS=(445 3389 139 137 138)

# Ports autorisés depuis réseau interne
# - 22 (SSH) - autorisé depuis réseau interne
ALLOWED_PORTS=(22)

# Générer plusieurs tentatives sur les ports bloqués
echo "📊 Génération de logs BLOCK (ports bloqués)..."
for port in "${BLOCKED_PORTS[@]}"; do
    echo "  → Port $port (devrait être BLOQUÉ)..."
    for i in $(seq 1 $ITERATIONS); do
        timeout 1 bash -c "</dev/tcp/$FIREWALL_IP/$port" 2>&1 || true
        sleep 0.2
    done
    sleep 0.5
done

echo ""
echo "📊 Génération de logs ALLOW (ports autorisés)..."
# Test ports autorisés depuis réseau interne
for port in "${ALLOWED_PORTS[@]}"; do
    echo "  → Port $port (devrait être AUTORISÉ depuis réseau interne)..."
    timeout 2 bash -c "</dev/tcp/$FIREWALL_IP/$port" 2>&1 || true
    sleep 0.5
done

echo ""
echo "✅ Tests terminés !"
echo ""
echo "Attendez 3-5 secondes puis vérifiez:"
echo "  1. Logs dans le firewall: docker exec firewall tail -30 /var/log/kern.log | grep -i ufw"
echo "  2. Logs dans le collecteur: docker exec logcollector tail -20 /var/log/firewall/*.log | grep -i ufw"
echo "  3. Interface Splunk: http://localhost:8000"
echo ""



