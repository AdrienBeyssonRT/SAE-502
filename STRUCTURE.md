# 📁 Structure du Projet AutoDeploy Firewall

## Arborescence complète

```
SAE502 final/
│
├── ansible.cfg                    # Configuration Ansible
├── docker-compose.yml             # Orchestration des conteneurs Docker
├── deploy-all.sh                  # Script unique : installation + déploiement + tests
├── DEPLOIEMENT.md                 # Guide complet de déploiement
├── STRUCTURE.md                   # Ce fichier - Structure du projet
├── PROJET.md                      # Compte rendu du projet
│
├── ansible/                       # Configuration Ansible
│   ├── inventory                  # Inventaire Ansible (localhost)
│   │
│   ├── playbooks/                 # Playbooks Ansible
│   │   ├── install.yml            # Installation Docker et préparation système
│   │   ├── deploy.yml             # Déploiement complet de l'infrastructure
│   │   ├── deploy-and-test.yml    # Déploiement complet avec tests automatiques
│   │   └── rules_update.yml       # Mise à jour dynamique des règles UFW
│   │
│   └── roles/                     # Rôles Ansible
│       ├── docker/                # Rôle : Installation Docker
│       │   ├── defaults/main.yml  # Variables par défaut
│       │   └── tasks/main.yml     # Tâches d'installation
│       │
│       ├── firewall/              # Rôle : Configuration pare-feu
│       │   ├── defaults/main.yml  # Variables par défaut
│       │   ├── tasks/main.yml     # Construction de l'image Docker
│       │   └── templates/
│       │       └── setup-ufw.sh.j2  # Template des règles UFW
│       │
│       ├── logcollector/          # Rôle : Collecteur de logs
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       ├── splunk/                 # Rôle : Configuration Splunk (si nécessaire)
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       ├── client/                # Rôle : Conteneur client de test
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       └── docker_compose/       # Rôle : Orchestration Docker
│           ├── defaults/main.yml
│           └── tasks/main.yml
│
└── containers/                    # Conteneurs Docker
    │
    ├── firewall/                  # Conteneur pare-feu UFW
    │   ├── Dockerfile             # Image Docker du pare-feu
    │   ├── entrypoint.sh          # Script de démarrage
    │   ├── rsyslog.conf           # Configuration rsyslog (envoi logs)
    │   └── setup-ufw.sh           # Script de configuration UFW
    │
    ├── logcollector/              # Conteneur collecteur de logs
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   └── rsyslog.conf           # Configuration rsyslog serveur
    │
    ├── splunk/                    # Conteneur Splunk pour supervision
    │   ├── inputs.conf            # Configuration réception syslog (UDP 514)
    │   └── props.conf             # Configuration parsing logs UFW
    │
    └── client/                    # Conteneur client de test
        ├── Dockerfile
        ├── entrypoint.sh
        ├── force-ufw-logs.sh      # Script optimisé pour générer des logs UFW
        └── test-rules-ufw.sh      # Script de test des règles UFW
```

## Description des composants

### Configuration Ansible

- **ansible.cfg** : Configuration globale (inventory, roles_path, become)
- **inventory** : Définit localhost comme cible de déploiement

### Playbooks

- **install.yml** : Installe Docker et prépare le système
- **deploy.yml** : Déploie toute l'infrastructure (images + conteneurs)
- **deploy-and-test.yml** : Déploiement complet avec tests automatiques et vérification
- **rules_update.yml** : Met à jour dynamiquement les règles UFW

### Scripts d'automatisation

- **deploy-all.sh** : Script unique qui fait tout automatiquement :
  - Installation des dépendances (Python, Ansible, Docker)
  - Mise à jour du système
  - Déploiement complet via Ansible
  - Tests et vérifications

### Rôles Ansible

Chaque rôle suit la structure standard Ansible :
- `defaults/` : Variables par défaut
- `tasks/` : Tâches à exécuter
- `templates/` : Templates Jinja2 (si nécessaire)

### Conteneurs Docker

Chaque conteneur contient :
- **Dockerfile** : Définition de l'image Docker
- **entrypoint.sh** : Script de démarrage du conteneur
- **Fichiers de configuration** : Spécifiques à chaque service

## Flux de déploiement

### Méthode automatique (recommandée)

1. **deploy-all.sh** → Fait tout automatiquement :
   - Installe toutes les dépendances (Python, Ansible, Docker)
   - Met à jour le système
   - Exécute `deploy-and-test.yml` pour déployer et tester

### Méthode manuelle

1. Installer manuellement : Python 3, pip, Ansible, Docker, Docker Compose
2. **deploy-and-test.yml** → 
   - Construit les images Docker de tous les conteneurs
   - Lance l'infrastructure complète via docker-compose
   - Configure automatiquement UFW avec les règles
   - Génère du trafic et vérifie les logs
3. **rules_update.yml** → Met à jour les règles UFW si nécessaire

## Réseaux Docker

Définis dans `docker-compose.yml` :
- `firewall_network` (172.20.0.0/16) : Réseau pour le firewall et le client
- `logs_network` (172.21.0.0/16) : Réseau pour le firewall et le logcollector
- `supervision_network` (172.22.0.0/16) : Réseau pour le logcollector et Splunk
- `tests_network` (172.23.0.0/16) : Réseau pour les tests

## Points d'entrée

- **Interface Splunk** : http://localhost:8000 (admin / splunk1RT3)
- **Client de test** : `docker exec -it client bash`
- **Logs** : `docker-compose logs -f`
- **Règles UFW** : `docker exec firewall ufw status verbose`

## Technologies utilisées

- **Ansible** : Automatisation du déploiement
- **Docker** : Conteneurisation des services
- **Docker Compose** : Orchestration des conteneurs
- **UFW** : Pare-feu Linux
- **rsyslog** : Collecte et centralisation des logs
- **Splunk** : Plateforme de supervision et analyse de logs
- **Syslog** : Protocole de réception des logs (UDP 514)


