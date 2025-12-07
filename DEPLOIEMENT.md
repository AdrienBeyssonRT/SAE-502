# 🚀 Guide de Déploiement - AutoDeploy Firewall

## 📋 Vue d'ensemble

Ce guide explique comment déployer complètement le système de pare-feu automatisé avec supervision des logs. Le déploiement peut être effectué en **une seule commande** ou étape par étape.

## ⚡ Installation et déploiement automatique (RECOMMANDÉ)

### Tout faire en UNE SEULE COMMANDE

Si vous venez de cloner le projet, exécutez simplement :

```bash
sudo ./deploy-all.sh
```

**Cette commande unique fait TOUT automatiquement :**
1. ✅ Mise à jour du système (apt update && upgrade)
2. ✅ Installation de Python 3 et pip
3. ✅ Installation d'Ansible
4. ✅ Installation de Docker et Docker Compose
5. ✅ Installation des modules Python nécessaires
6. ✅ Configuration des permissions Docker
7. ✅ Reconstruction des conteneurs
8. ✅ Démarrage de l'infrastructure
9. ✅ Configuration UFW avec logging
10. ✅ Génération de trafic pour créer des logs
11. ✅ Vérification complète de la chaîne de logs
12. ✅ Affichage d'un résumé complet

**C'est tout !** À la fin, l'interface web est disponible sur http://localhost:5000

---

## 📋 Installation étape par étape (optionnel)

Si vous préférez faire les étapes séparément :

### 1. Installation des dépendances manuellement

Installez manuellement : Python 3, pip, Ansible, Docker, Docker Compose

### 2. Déploiement

```bash
ansible-playbook ansible/playbooks/deploy-and-test.yml
```

## 📋 Déploiement manuel (si nécessaire)

### Prérequis

- Machine Linux (Ubuntu 22.04 recommandé)
- Python 3 avec pip
- Ansible 2.9+
- Docker et Docker Compose
- Accès sudo/root

### Installation en une commande

```bash
ansible-playbook ansible/playbooks/deploy-and-test.yml
```

**Cette commande unique fait automatiquement :**
1. ✅ Installation de Docker (si nécessaire)
2. ✅ Reconstruction de tous les conteneurs
3. ✅ Démarrage de l'infrastructure
4. ✅ Configuration UFW avec logging activé
5. ✅ Génération de trafic pour créer des logs
6. ✅ Vérification complète de la chaîne de logs
7. ✅ Vérification de la catégorisation (BLOCK/ALLOW)
8. ✅ Affichage d'un résumé avec statistiques

**Résultat :** Interface web opérationnelle sur **http://localhost:5000** avec logs correctement catégorisés.

## 📦 Architecture déployée

### Conteneurs Docker

| Conteneur | Rôle | Réseaux | Ports |
|-----------|------|---------|-------|
| **firewall** | Pare-feu UFW | firewall_network, logs_network | - |
| **logcollector** | Serveur rsyslog | logs_network, supervision_network | 514/udp |
| **supervision** | Application web Flask | supervision_network | 5000 |
| **client** | Conteneur de test | firewall_network, tests_network | - |

### Réseaux Docker

- `firewall_network` (172.20.0.0/16) : Réseau pour firewall et client
- `logs_network` (172.21.0.0/16) : Réseau pour firewall et logcollector
- `supervision_network` (172.22.0.0/16) : Réseau pour logcollector et supervision
- `tests_network` (172.23.0.0/16) : Réseau pour les tests

## 🔄 Flux des logs

```
┌──────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│ Firewall │ ───> │ Logcollector │ ───> │ Supervision │ ───> │ Interface Web│
│   UFW    │ UDP  │    rsyslog   │ Vol  │    Flask    │ HTTP │  Port 5000   │
└──────────┘ 514  └──────────────┘      └─────────────┘      └──────────────┘
```

1. **Génération** : UFW génère des logs dans `/var/log/kern.log`
2. **Envoi** : rsyslog dans le firewall envoie les logs au logcollector via UDP 514
3. **Collecte** : rsyslog dans le logcollector stocke les logs dans `/var/log/firewall/`
4. **Parsing** : L'application Flask lit et parse les logs depuis le volume partagé
5. **Affichage** : L'interface web affiche les logs catégorisés (BLOCK, ALLOW, LIMIT)

## 🔒 Règles UFW configurées

### Règles par défaut
- `deny incoming` : Blocage de tout le trafic entrant
- `allow outgoing` : Autorisation du trafic sortant
- `deny routed` : Blocage du routage non autorisé

### Services autorisés
- **SSH interne** : `allow from 172.20.0.0/16 to any port 22`
- **Envoi des logs** : `allow out 514/udp`
- **DNS sortant** : `allow out 53/udp` et `53/tcp`
- **Web sortant** : `allow out 80/tcp` et `443/tcp`

### Services bloqués
- **SMB/NetBIOS** : ports 137, 138, 139, 445
- **RDP** : port 3389
- **HTTP** : port 80 (pas de service, donc bloqué)

### Sécurité
- **Limitation SSH** : `limit 22/tcp` (protection brute-force)
- **Journalisation** : `logging high`

## 🧪 Tests automatiques

Le playbook `deploy-and-test.yml` génère automatiquement du trafic sur :

| Port | Action attendue | Catégorie |
|------|----------------|-----------|
| 445 | Bloqué | **BLOCK** |
| 3389 | Bloqué | **BLOCK** |
| 139 | Bloqué | **BLOCK** |
| 80 | Bloqué | **BLOCK** |
| 22 | Autorisé | **ALLOW** |

## 📊 Vérification du déploiement

### 1. Vérifier les conteneurs

```bash
docker ps
```

Vous devriez voir : `firewall`, `logcollector`, `supervision`, `client`

### 2. Vérifier UFW

```bash
docker exec firewall ufw status verbose
```

Vérifiez que :
- `Status: active`
- `Logging: on (high)`

### 3. Vérifier les logs dans le firewall

```bash
docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
```

Vous devriez voir des logs UFW avec `[UFW BLOCK]` ou `[UFW ALLOW]`.

### 4. Vérifier les logs dans le collecteur

```bash
docker exec logcollector tail -20 /var/log/firewall/*.log | grep -i ufw
```

Vous devriez voir les mêmes logs que dans le firewall.

### 5. Vérifier l'interface web

Ouvrez **http://localhost:5000** dans votre navigateur.

Vous devriez voir :
- ✅ Statistiques (total logs, tentatives bloquées, connexions autorisées)
- ✅ Logs détaillés avec IP sources, ports, protocoles
- ✅ Catégorisation correcte (BLOCK, ALLOW, LIMIT)
- ✅ Top IP sources, top ports, répartition par protocole

### 6. Vérifier l'API

```bash
# Statistiques
curl http://localhost:5000/api/stats

# Logs récents
curl http://localhost:5000/api/recent

# Debug
curl http://localhost:5000/api/debug
```

## 🛠️ Déploiement étape par étape (optionnel)

Si vous préférez déployer manuellement :

### Étape 1 : Installation de Docker

```bash
ansible-playbook ansible/playbooks/install.yml
```

### Étape 2 : Déploiement de l'infrastructure

```bash
ansible-playbook ansible/playbooks/deploy.yml
```

### Étape 3 : Génération de trafic et vérification

```bash
# Générer du trafic
docker exec client /usr/local/bin/force-ufw-logs.sh firewall 5

# Attendre 5 secondes
sleep 5

# Vérifier les logs
docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
docker exec logcollector tail -20 /var/log/firewall/*.log | grep -i ufw
```

## 🔧 Commandes utiles

### Voir les logs en temps réel

```bash
# Logs UFW dans le firewall
docker exec firewall tail -f /var/log/kern.log | grep UFW

# Logs dans le collecteur
docker exec logcollector tail -f /var/log/firewall/*.log | grep UFW

# Logs de tous les conteneurs
docker-compose logs -f
```

### Tester manuellement

```bash
# Entrer dans le conteneur client
docker exec -it client bash

# Générer du trafic
/usr/local/bin/force-ufw-logs.sh firewall 5

# Tester les règles
/usr/local/bin/test-rules-ufw.sh
```

### Redémarrer l'infrastructure

```bash
docker-compose down
docker-compose up -d --build
```

### Mettre à jour les règles UFW

```bash
ansible-playbook ansible/playbooks/rules_update.yml
```

## 🐛 Dépannage

### Les conteneurs ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'état
docker-compose ps

# Redémarrer
docker-compose restart
```

### Aucun log UFW dans le firewall

1. Vérifier que UFW est actif :
   ```bash
   docker exec firewall ufw status verbose
   ```

2. Activer le logging si nécessaire :
   ```bash
   docker exec firewall ufw logging high
   ```

3. Générer du trafic :
   ```bash
   docker exec client /usr/local/bin/force-ufw-logs.sh firewall 5
   ```

4. Vérifier immédiatement (dans les 2 secondes) :
   ```bash
   docker exec firewall tail -30 /var/log/kern.log | grep -i ufw
   ```

### Les logs ne remontent pas au collecteur

1. Vérifier que rsyslog fonctionne dans le firewall :
   ```bash
   docker exec firewall ps aux | grep rsyslog
   ```

2. Vérifier la connexion réseau :
   ```bash
   docker exec firewall ping -c 2 logcollector
   ```

3. Vérifier que rsyslog fonctionne dans le logcollector :
   ```bash
   docker exec logcollector ps aux | grep rsyslog
   ```

4. Vérifier les logs du collecteur :
   ```bash
   docker exec logcollector ls -la /var/log/firewall/
   docker exec logcollector tail -20 /var/log/firewall/*.log
   ```

### Les logs ne s'affichent pas dans l'interface web

1. Vérifier que le conteneur supervision est en cours d'exécution :
   ```bash
   docker ps | grep supervision
   ```

2. Vérifier l'API :
   ```bash
   curl http://localhost:5000/api/debug
   ```

3. Vérifier les logs de supervision :
   ```bash
   docker-compose logs supervision
   ```

4. Redémarrer le conteneur supervision :
   ```bash
   docker-compose restart supervision
   ```

### Les logs ne sont pas correctement catégorisés

1. Vérifier les logs bruts dans le collecteur :
   ```bash
   docker exec logcollector tail -10 /var/log/firewall/*.log
   ```

2. Vérifier que les logs contiennent `[UFW BLOCK]` ou `[UFW ALLOW]` :
   ```bash
   docker exec logcollector grep -i "UFW BLOCK\|UFW ALLOW" /var/log/firewall/*.log | head -5
   ```

3. Vérifier l'API de debug pour voir les logs parsés :
   ```bash
   curl http://localhost:5000/api/debug | jq '.parsed_samples'
   ```

## 📈 Résultat attendu

Après le déploiement, vous devriez avoir :

- ✅ **4 conteneurs** en cours d'exécution
- ✅ **UFW actif** avec logging high
- ✅ **Logs UFW** générés dans `/var/log/kern.log` du firewall
- ✅ **Logs collectés** dans `/var/log/firewall/*.log` du logcollector
- ✅ **Logs parsés** et catégorisés dans l'interface web
- ✅ **Statistiques** affichées (BLOCK, ALLOW, IP sources, ports)

## 🔗 Liens utiles

- **Interface web** : http://localhost:5000
- **API stats** : http://localhost:5000/api/stats
- **API logs** : http://localhost:5000/api/logs
- **API debug** : http://localhost:5000/api/debug

## 📚 Documentation complémentaire

- **[STRUCTURE.md](STRUCTURE.md)** : Structure complète du projet
- **[PROJET.md](PROJET.md)** : Compte rendu détaillé du projet

