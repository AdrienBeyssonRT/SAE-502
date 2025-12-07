# 🔍 Diagnostic Rapide - Pas de logs UFW

## ⚠️ Problème : Aucun log n'apparaît

Si vous n'avez aucun log dans l'interface web, suivez ces étapes :

## 🔍 Étape 1 : Vérifier que UFW génère des logs

```bash
# 1. Vérifier le statut UFW
docker exec firewall ufw status verbose
```

**Vous devez voir :**
- `Status: active`
- `Logging: on (high)`

**Si le logging n'est pas "on (high)" :**
```bash
docker exec firewall ufw logging high
```

## 🔍 Étape 2 : Générer de vraies connexions TCP

**IMPORTANT :** Les scans `nmap` ne génèrent **PAS** toujours de logs UFW. Il faut créer de **vraies connexions TCP**.

```bash
# Option A : Utiliser le script automatique
docker exec client bash /usr/local/bin/force-ufw-logs.sh

# Option B : Commandes manuelles
docker exec client bash -c "timeout 2 bash -c '</dev/tcp/firewall/445' 2>&1 || true"
docker exec client bash -c "timeout 2 bash -c '</dev/tcp/firewall/3389' 2>&1 || true"
docker exec client bash -c "timeout 2 bash -c '</dev/tcp/firewall/139' 2>&1 || true"
```

## 🔍 Étape 3 : Vérifier IMMÉDIATEMENT les logs dans le firewall

**Dans les 2 secondes** après avoir généré le trafic :

```bash
docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
```

**Si vous voyez des logs**, UFW fonctionne. Le problème est ailleurs.

**Si vous ne voyez RIEN**, UFW ne génère pas de logs. Continuez avec l'étape 4.

## 🔍 Étape 4 : Réinitialiser UFW si nécessaire

Si UFW ne génère pas de logs, réinitialisez-le :

```bash
# Entrer dans le firewall
docker exec -it firewall bash

# Réinitialiser UFW
ufw --force reset

# Reconfigurer
ufw default deny incoming
ufw default allow outgoing
ufw logging high
ufw deny 445/tcp comment 'Blocage SMB'
ufw deny 3389/tcp comment 'Blocage RDP'
ufw deny 139/tcp comment 'Blocage NetBIOS'
ufw deny 137/udp comment 'Blocage NetBIOS'
ufw deny 138/udp comment 'Blocage NetBIOS'
ufw allow from 172.20.0.0/16 to any port 22 proto tcp comment 'SSH interne'
ufw allow out 514/udp comment 'Envoi logs vers logcollector'
ufw --force enable

# Vérifier
ufw status verbose

# Sortir
exit
```

## 🔍 Étape 5 : Tester à nouveau

```bash
# Générer du trafic
docker exec client bash /usr/local/bin/force-ufw-logs.sh

# Vérifier IMMÉDIATEMENT (dans les 2 secondes)
docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
```

**Vous devriez voir des logs comme :**
```
Dec  7 11:23:15 firewall kernel: [UFW BLOCK] IN=eth0 OUT= MAC=... SRC=172.20.0.2 DST=172.20.0.3 ... PROTO=TCP DPT=445 ...
```

## 🔍 Étape 6 : Vérifier que les logs sont envoyés au collecteur

```bash
# Attendre 5 secondes après le test
sleep 5

# Vérifier dans le logcollector
docker exec logcollector tail -20 /var/log/firewall/*.log | grep -i ufw
```

**Si vous voyez des logs**, le collecteur fonctionne.

## 🔍 Étape 7 : Vérifier l'interface web

1. Ouvrez http://localhost:5000
2. Rafraîchissez la page (F5)
3. Vous devriez voir les logs avec tous les détails

## 🎯 Test complet en une commande

```bash
# Générer du trafic + vérifier les logs
docker exec client bash /usr/local/bin/force-ufw-logs.sh && sleep 3 && docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
```

## 🚨 Si toujours rien

1. Vérifiez que le conteneur firewall est bien en cours d'exécution :
   ```bash
   docker ps | grep firewall
   ```

2. Vérifiez que rsyslog fonctionne dans le firewall :
   ```bash
   docker exec firewall ps aux | grep rsyslog
   ```

3. Vérifiez la connexion réseau :
   ```bash
   docker exec firewall ping -c 2 logcollector
   ```

4. Vérifiez l'API de debug :
   - Ouvrez http://localhost:5000/api/debug
   - Regardez `parsed_count` et `sample_logs`

