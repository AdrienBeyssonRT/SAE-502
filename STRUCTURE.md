# Structure du Projet AutoDeploy Firewall

## 📁 Arborescence complète

```
SAE502 final/
│
├── ansible.cfg                    # Configuration Ansible
├── docker-compose.yml             # Orchestration des conteneurs
├── README.md                      # Documentation principale
├── QUICKSTART.md                  # Guide de démarrage rapide
├── PROJET.md                      # Documentation du projet
├── STRUCTURE.md                   # Ce fichier
├── .gitignore                     # Fichiers à ignorer
│
├── ansible/
│   ├── inventory                  # Inventaire Ansible (localhost)
│   │
│   ├── playbooks/                 # Playbooks Ansible
│   │   ├── install.yml            # Installation Docker
│   │   ├── deploy.yml             # Déploiement complet
│   │   ├── rules_update.yml       # Mise à jour des règles UFW
│   │   └── tests.yml              # Tests automatiques
│   │
│   └── roles/                     # Rôles Ansible
│       ├── docker/                # Installation Docker
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       ├── firewall/              # Configuration firewall
│       │   ├── defaults/main.yml
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       └── setup-ufw.sh.j2
│       │
│       ├── logcollector/          # Configuration logcollector
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       ├── supervision/            # Configuration supervision
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       ├── client/                 # Configuration client
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       │
│       └── docker_compose/         # Orchestration Docker
│           ├── defaults/main.yml
│           └── tasks/main.yml
│
└── containers/                     # Conteneurs Docker
    │
    ├── firewall/                   # Conteneur pare-feu
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   ├── rsyslog.conf
    │   └── setup-ufw.sh
    │
    ├── logcollector/               # Conteneur collecteur de logs
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   └── rsyslog.conf
    │
    ├── supervision/                # Conteneur supervision
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   ├── requirements.txt
    │   ├── supervision_app.py
    │   ├── templates/
    │   │   └── dashboard.html
    │   └── static/
    │       └── style.css
    │
    └── client/                     # Conteneur client de test
        ├── Dockerfile
        ├── entrypoint.sh
        └── test_scripts/
            ├── test_ssh.sh
            ├── test_ports.sh
            └── test_web.sh
```

## 🔍 Description des composants

### Configuration Ansible

- **ansible.cfg** : Configuration globale (inventory, roles_path, become)
- **inventory** : Définit localhost comme cible

### Playbooks

- **install.yml** : Installe Docker et prépare le système
- **deploy.yml** : Déploie toute l'infrastructure (images + conteneurs)
- **rules_update.yml** : Met à jour dynamiquement les règles UFW
- **tests.yml** : Exécute des tests automatiques et vérifie les logs

### Rôles Ansible

Chaque rôle suit la structure standard Ansible :
- `defaults/` : Variables par défaut
- `tasks/` : Tâches à exécuter
- `templates/` : Templates Jinja2 (si nécessaire)

### Conteneurs Docker

Chaque conteneur contient :
- **Dockerfile** : Définition de l'image
- **entrypoint.sh** : Script de démarrage
- **Fichiers de configuration** : Spécifiques à chaque service

## 🔗 Flux de déploiement

1. **install.yml** → Installe Docker
2. **deploy.yml** → 
   - Construit les images (firewall, logcollector, supervision, client)
   - Lance docker-compose pour orchestrer les conteneurs
3. **rules_update.yml** → Met à jour les règles UFW si nécessaire
4. **tests.yml** → Vérifie le bon fonctionnement

## 📊 Réseaux Docker

Définis dans `docker-compose.yml` :
- `firewall_network` : 172.20.0.0/16
- `logs_network` : 172.21.0.0/16
- `supervision_network` : 172.22.0.0/16
- `tests_network` : 172.23.0.0/16

## 🎯 Points d'entrée

- **Supervision web** : http://localhost:5000
- **Client de test** : `docker exec -it client bash`
- **Logs** : `docker-compose logs -f`
- **Règles UFW** : `docker exec firewall ufw status verbose`



