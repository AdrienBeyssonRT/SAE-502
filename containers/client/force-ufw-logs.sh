#!/bin/bash
# Script optimisé pour générer des logs UFW avec de vraies connexions TCP
# Utilisé par le playbook deploy-and-test.yml

FIREWALL_IP="${1:-firewall}"
ITERATIONS="${2:-5}"

# Générer plusieurs tentatives sur les ports bloqués (445, 3389, 139, 80)
for port in 445 3389 139 80; do
    for i in $(seq 1 $ITERATIONS); do
        timeout 1 bash -c "</dev/tcp/$FIREWALL_IP/$port" 2>&1 || true
        sleep 0.2
    done
done

# Test port 22 (autorisé depuis réseau interne)
timeout 2 bash -c "</dev/tcp/$FIREWALL_IP/22" 2>&1 || true



