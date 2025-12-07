# AutoDeploy Firewall - Déploiement automatisé d'un pare-feu avec supervision visuelle

## 📋 Description du projet

Ce projet automatise le déploiement complet d'un pare-feu Linux (UFW) avec centralisation des logs et supervision visuelle. L'ensemble est déployable via Ansible sans intervention manuelle.

## 🏗️ Architecture

Le projet utilise une machine virtuelle Linux exécutant 4 conteneurs Docker :

- **firewall** : Pare-feu UFW avec règles de sécurité et journalisation
- **logcollector** : Serveur rsyslog pour centraliser les logs
- **supervision** : Application web Flask pour visualiser les logs en temps réel
- **client** : Conteneur de test avec outils (nmap, curl, nc, ping)

### Réseaux Docker

- `firewall_network` (172.20.0.0/16) : Réseau pour le firewall et le client
- `logs_network` (172.21.0.0/16) : Réseau pour le firewall et le logcollector
- `supervision_network` (172.22.0.0/16) : Réseau pour le logcollector et la supervision
- `tests_network` (172.23.0.0/16) : Réseau pour les tests

## 🔒 Règles UFW configurées

### Règles par défaut
- `deny incoming` : Blocage de tout le trafic entrant
- `allow outgoing` : Autorisation du trafic sortant
- `deny routed` : Blocage du routage non autorisé

### Services autorisés
- SSH interne : `allow from 172.20.0.0/16 to any port 22`
- Envoi des logs : `allow out 514/udp`
- DNS sortant : `allow out 53`
- Web sortant : `allow out 80/tcp et 443/tcp`

### Services bloqués
- SMB/NetBIOS : ports 137, 138, 139, 445
- RDP : port 3389

### Sécurité
- Limitation SSH : `limit 22/tcp` (protection brute-force)
- Journalisation : `logging high`

## 📦 Prérequis

- Machine virtuelle Linux (Ubuntu 22.04 recommandé)
- Python 3 avec pip
- Ansible 2.9+
- Accès sudo/root

## 🚀 Installation et déploiement

Pour un guide d'installation détaillé, consultez **[INSTALLATION.md](INSTALLATION.md)**.

### Installation rapide

```bash
# 1. Installation de Docker
ansible-playbook ansible/playbooks/install.yml

# 2. Déploiement complet
ansible-playbook ansible/playbooks/deploy.yml

# 3. Accéder à la supervision
# Ouvrir http://localhost:5000
```

### Commandes supplémentaires

```bash
# Mise à jour des règles UFW
ansible-playbook ansible/playbooks/rules_update.yml

# Tests automatiques
ansible-playbook ansible/playbooks/tests.yml
```

## 🎯 Utilisation

### Accéder à la supervision

Ouvrez votre navigateur sur : **http://localhost:5000**

L'interface affiche :
- Statistiques en temps réel (total logs, tentatives bloquées, connexions autorisées)
- Logs détaillés avec IP sources, ports, protocoles
- Visualisation des actions UFW (BLOCK, ALLOW, LIMIT)

### Utiliser le conteneur client

```bash
docker exec -it client bash
```

Dans le conteneur, vous pouvez tester :
```bash
# Scan de ports
nmap -p 22,80,443,445 firewall

# Test SSH
nc -zv firewall 22

# Test HTTP
curl http://firewall:80

# Test ping
ping firewall
```

### Voir les logs

```bash
# Logs de tous les conteneurs
docker-compose logs -f

# Logs du firewall uniquement
docker-compose logs -f firewall

# Logs dans le collecteur
docker exec logcollector tail -f /var/log/firewall/*.log
```

### Vérifier les règles UFW

```bash
docker exec firewall ufw status verbose
```

## 📁 Structure du projet

Pour une description détaillée de la structure, consultez **[STRUCTURE.md](STRUCTURE.md)**.

```
.
├── ansible/                   # Configuration Ansible
│   ├── inventory              # Inventaire Ansible
│   ├── roles/                 # Rôles Ansible
│   └── playbooks/             # Playbooks de déploiement
├── containers/                # Conteneurs Docker
│   ├── firewall/              # Pare-feu UFW
│   ├── logcollector/          # Collecteur de logs
│   ├── supervision/           # Application de supervision
│   └── client/                # Client de test
├── docker-compose.yml         # Orchestration des conteneurs
├── ansible.cfg                # Configuration Ansible
├── README.md                  # Documentation principale
├── INSTALLATION.md            # Guide d'installation
├── STRUCTURE.md               # Structure du projet
└── PROJET.md                  # Compte rendu du projet
```

## 🔧 Rôles Ansible

- **docker** : Installation de Docker et préparation du système
- **firewall** : Construction de l'image et configuration UFW
- **logcollector** : Déploiement du serveur rsyslog
- **supervision** : Installation et configuration de l'application Flask
- **client** : Installation des outils de test
- **docker_compose** : Lancement de l'infrastructure complète

## 🧪 Tests

Le playbook `tests.yml` exécute automatiquement :
1. Ping vers le firewall
2. Scan de ports avec nmap
3. Tentative de connexion SSH
4. Tentative de connexion HTTP
5. Tentative de connexion SMB (devrait être bloquée)
6. Vérification des logs dans le collecteur
7. Vérification de l'API de supervision

## 📊 Supervision

L'application de supervision (Flask) fournit :
- **API REST** :
  - `/api/logs` : Liste des logs
  - `/api/stats` : Statistiques agrégées
  - `/api/recent` : Logs récents (50 dernières lignes)
  - `/api/debug` : Informations de debug
- **Interface web** : Tableau de bord détaillé avec :
  - Vue d'ensemble (total logs, tentatives bloquées, connexions autorisées)
  - Top IP sources
  - Top ports ciblés
  - Répartition par protocole
  - Logs détaillés avec IP source/destination, ports, protocole, action

## 🛠️ Dépannage

### Les conteneurs ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'état
docker-compose ps

# Redémarrer
docker-compose restart
```

### Les logs n'apparaissent pas dans la supervision

1. Vérifier que rsyslog fonctionne dans le firewall :
```bash
docker exec firewall ps aux | grep rsyslog
```

2. Vérifier la connexion réseau :
```bash
docker exec firewall ping logcollector
```

3. Vérifier les logs du collecteur :
```bash
docker exec logcollector ls -la /var/log/firewall/
```

### UFW ne s'applique pas

```bash
# Vérifier le statut
docker exec firewall ufw status verbose

# Voir les logs UFW
docker exec firewall tail -f /var/log/ufw.log
```

## 📝 Notes

- Le projet nécessite des privilèges élevés pour UFW (NET_ADMIN, NET_RAW)
- Les logs sont stockés dans un volume Docker persistant
- La supervision se met à jour automatiquement toutes les 5 secondes
- Les règles UFW peuvent être modifiées dynamiquement via `rules_update.yml`
- Pour générer des logs UFW, utilisez de vraies connexions TCP (pas seulement des scans nmap)

## 📚 Documentation

- **[INSTALLATION.md](INSTALLATION.md)** : Guide d'installation détaillé
- **[STRUCTURE.md](STRUCTURE.md)** : Structure complète du projet
- **[PROJET.md](PROJET.md)** : Compte rendu du projet

## 👥 Auteurs

Projet SAÉ 5.02 - AutoDeploy Firewall

## 📄 Licence

Ce projet est réalisé dans le cadre académique.



