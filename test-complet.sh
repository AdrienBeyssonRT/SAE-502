#!/bin/bash
# Script unique pour tester complètement le système de logs UFW
# Ce script génère du trafic, vérifie les logs et affiche les résultats

set -e

FIREWALL_IP="firewall"
CLIENT_CONTAINER="client"
FIREWALL_CONTAINER="firewall"
LOGCOLLECTOR_CONTAINER="logcollector"

echo "=========================================="
echo "  TEST COMPLET DU SYSTÈME DE LOGS UFW"
echo "=========================================="
echo ""

# Étape 1 : Vérifier que les conteneurs sont en cours d'exécution
echo "📋 Étape 1 : Vérification des conteneurs..."
if ! docker ps | grep -q "$FIREWALL_CONTAINER"; then
    echo "❌ ERREUR: Le conteneur $FIREWALL_CONTAINER n'est pas en cours d'exécution"
    exit 1
fi
if ! docker ps | grep -q "$LOGCOLLECTOR_CONTAINER"; then
    echo "❌ ERREUR: Le conteneur $LOGCOLLECTOR_CONTAINER n'est pas en cours d'exécution"
    exit 1
fi
if ! docker ps | grep -q "$CLIENT_CONTAINER"; then
    echo "❌ ERREUR: Le conteneur $CLIENT_CONTAINER n'est pas en cours d'exécution"
    exit 1
fi
echo "✅ Tous les conteneurs sont en cours d'exécution"
echo ""

# Étape 2 : Vérifier le statut UFW
echo "📋 Étape 2 : Vérification du statut UFW..."
UFW_STATUS=$(docker exec $FIREWALL_CONTAINER ufw status verbose 2>/dev/null || echo "")
if echo "$UFW_STATUS" | grep -qi "Status: active"; then
    echo "✅ UFW est actif"
else
    echo "❌ ERREUR: UFW n'est pas actif"
    echo "Tentative de réactivation..."
    docker exec $FIREWALL_CONTAINER ufw --force enable || true
fi

if echo "$UFW_STATUS" | grep -qi "Logging: on (high)"; then
    echo "✅ Le logging UFW est activé (high)"
else
    echo "⚠️  Le logging UFW n'est pas activé, activation..."
    docker exec $FIREWALL_CONTAINER ufw logging high
    echo "✅ Logging activé"
fi
echo ""

# Étape 3 : Nettoyer les anciens logs pour un test propre
echo "📋 Étape 3 : Nettoyage des anciens logs (optionnel)..."
docker exec $FIREWALL_CONTAINER sh -c "echo '' > /var/log/kern.log" 2>/dev/null || true
echo "✅ Nettoyage effectué"
echo ""

# Étape 4 : Générer du trafic pour créer des logs UFW
echo "📋 Étape 4 : Génération de trafic pour créer des logs UFW..."
echo "   Génération de connexions TCP sur les ports bloqués..."

# Générer plusieurs tentatives sur chaque port bloqué
for port in 445 3389 139 80; do
    echo "   → Test port $port (devrait être BLOQUÉ)..."
    for i in {1..5}; do
        docker exec $CLIENT_CONTAINER timeout 1 bash -c "</dev/tcp/$FIREWALL_IP/$port" 2>&1 || true
        sleep 0.2
    done
done

# Test port 22 (devrait être autorisé)
echo "   → Test port 22 (devrait être AUTORISÉ)..."
docker exec $CLIENT_CONTAINER timeout 2 bash -c "</dev/tcp/$FIREWALL_IP/22" 2>&1 || true

echo "✅ Trafic généré"
echo ""

# Étape 5 : Attendre que les logs soient écrits
echo "📋 Étape 5 : Attente de l'écriture des logs (3 secondes)..."
sleep 3
echo "✅ Attente terminée"
echo ""

# Étape 6 : Vérifier les logs dans le firewall
echo "📋 Étape 6 : Vérification des logs dans le firewall..."
UFW_LOGS=$(docker exec $FIREWALL_CONTAINER tail -50 /var/log/kern.log | grep -i ufw || echo "")
if [ -z "$UFW_LOGS" ]; then
    echo "❌ ERREUR: Aucun log UFW trouvé dans /var/log/kern.log"
    echo ""
    echo "Dernières lignes de /var/log/kern.log:"
    docker exec $FIREWALL_CONTAINER tail -10 /var/log/kern.log
    echo ""
    echo "Vérifiez que:"
    echo "  1. UFW est actif: docker exec $FIREWALL_CONTAINER ufw status"
    echo "  2. Le logging est activé: docker exec $FIREWALL_CONTAINER ufw status verbose | grep Logging"
    exit 1
else
    LOG_COUNT=$(echo "$UFW_LOGS" | wc -l)
    echo "✅ $LOG_COUNT logs UFW trouvés dans le firewall"
    echo ""
    echo "Exemples de logs UFW:"
    echo "$UFW_LOGS" | head -3 | sed 's/^/   /'
fi
echo ""

# Étape 7 : Vérifier que les logs sont envoyés au collecteur
echo "📋 Étape 7 : Vérification des logs dans le collecteur..."
sleep 2  # Attendre que rsyslog envoie les logs
COLLECTOR_LOGS=$(docker exec $LOGCOLLECTOR_CONTAINER sh -c "tail -50 /var/log/firewall/*.log 2>/dev/null | grep -i ufw" || echo "")
if [ -z "$COLLECTOR_LOGS" ]; then
    echo "⚠️  ATTENTION: Aucun log UFW trouvé dans le collecteur"
    echo ""
    echo "Vérification de la connexion réseau..."
    docker exec $FIREWALL_CONTAINER ping -c 2 $LOGCOLLECTOR_CONTAINER || echo "   ❌ Pas de connexion réseau"
    echo ""
    echo "Vérification de rsyslog dans le firewall..."
    docker exec $FIREWALL_CONTAINER ps aux | grep rsyslog || echo "   ❌ rsyslog n'est pas en cours d'exécution"
    echo ""
    echo "Derniers logs du collecteur (tous):"
    docker exec $LOGCOLLECTOR_CONTAINER sh -c "tail -10 /var/log/firewall/*.log 2>/dev/null" || echo "   Aucun fichier de log"
else
    LOG_COUNT_COLLECTOR=$(echo "$COLLECTOR_LOGS" | wc -l)
    echo "✅ $LOG_COUNT_COLLECTOR logs UFW trouvés dans le collecteur"
    echo ""
    echo "Exemples de logs dans le collecteur:"
    echo "$COLLECTOR_LOGS" | head -3 | sed 's/^/   /'
fi
echo ""

# Étape 8 : Vérifier l'interface web
echo "📋 Étape 8 : Vérification de l'interface web..."
sleep 2
API_RESPONSE=$(curl -s http://localhost:5000/api/stats 2>/dev/null || echo "")
if [ -z "$API_RESPONSE" ]; then
    echo "⚠️  ATTENTION: L'API de supervision ne répond pas"
    echo "   Vérifiez que le conteneur supervision est en cours d'exécution:"
    echo "   docker ps | grep supervision"
else
    TOTAL_LOGS=$(echo "$API_RESPONSE" | grep -o '"total":[0-9]*' | grep -o '[0-9]*' || echo "0")
    BLOCKED=$(echo "$API_RESPONSE" | grep -o '"blocked_attempts":[0-9]*' | grep -o '[0-9]*' || echo "0")
    ALLOWED=$(echo "$API_RESPONSE" | grep -o '"allowed_connections":[0-9]*' | grep -o '[0-9]*' || echo "0")
    
    if [ "$TOTAL_LOGS" -gt 0 ]; then
        echo "✅ Interface web opérationnelle"
        echo "   Total de logs: $TOTAL_LOGS"
        echo "   Tentatives bloquées: $BLOCKED"
        echo "   Connexions autorisées: $ALLOWED"
    else
        echo "⚠️  Interface web opérationnelle mais aucun log parsé"
        echo "   Vérifiez http://localhost:5000/api/debug pour plus d'informations"
    fi
fi
echo ""

# Résumé final
echo "=========================================="
echo "  RÉSUMÉ DU TEST"
echo "=========================================="
echo ""
echo "✅ Conteneurs: OK"
echo "$([ -n "$UFW_LOGS" ] && echo "✅" || echo "❌") Logs UFW dans le firewall: $([ -n "$UFW_LOGS" ] && echo "OK" || echo "ÉCHEC")"
echo "$([ -n "$COLLECTOR_LOGS" ] && echo "✅" || echo "⚠️ ") Logs dans le collecteur: $([ -n "$COLLECTOR_LOGS" ] && echo "OK" || echo "ATTENTION")"
echo "$([ -n "$API_RESPONSE" ] && [ "$TOTAL_LOGS" -gt 0 ] && echo "✅" || echo "⚠️ ") Interface web: $([ -n "$API_RESPONSE" ] && [ "$TOTAL_LOGS" -gt 0 ] && echo "OK" || echo "ATTENTION")"
echo ""
echo "🌐 Accédez à http://localhost:5000 pour voir l'interface de supervision"
echo ""
echo "Pour voir les logs en temps réel:"
echo "  docker exec $FIREWALL_CONTAINER tail -f /var/log/kern.log | grep UFW"
echo "  docker exec $LOGCOLLECTOR_CONTAINER tail -f /var/log/firewall/*.log | grep UFW"
echo ""

