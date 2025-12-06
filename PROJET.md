# Documentation du Projet - AutoDeploy Firewall

## 📋 Conformité au cahier des charges

Ce projet répond intégralement aux exigences du cahier des charges SAÉ 5.02 :

### ✅ Infrastructure technique

- [x] **4 conteneurs Docker** :
  - `firewall` : Pare-feu UFW avec règles de sécurité
  - `logcollector` : Serveur rsyslog pour centralisation
  - `supervision` : Application Flask de visualisation
  - `client` : Conteneur de test avec outils réseau

- [x] **4 réseaux Docker distincts** :
  - `firewall_network` (172.20.0.0/16)
  - `logs_network` (172.21.0.0/16)
  - `supervision_network` (172.22.0.0/16)
  - `tests_network` (172.23.0.0/16)

### ✅ Services fonctionnels

- [x] **Firewall** : UFW configuré avec toutes les règles spécifiées
- [x] **Logcollector** : rsyslog en mode serveur UDP (port 514)
- [x] **Supervision** : Interface web avec tableaux de bord et API REST
- [x] **Client** : Outils de test (nmap, curl, nc, ping)

### ✅ Règles UFW implémentées

- [x] `deny incoming`, `allow outgoing`, `deny routed`
- [x] SSH interne : `allow from 172.20.0.0/16 to any port 22`
- [x] Envoi logs : `allow out 514/udp`
- [x] DNS sortant : `allow out 53`
- [x] Web sortant : `allow out 80/tcp et 443/tcp`
- [x] Blocage SMB/NetBIOS : ports 137, 138, 139, 445
- [x] Blocage RDP : port 3389
- [x] Limitation SSH : `limit 22/tcp`
- [x] Journalisation : `logging high`

### ✅ Rôles Ansible

- [x] **docker** : Installation Docker + préparation système
- [x] **firewall** : Construction image + configuration UFW
- [x] **logcollector** : Déploiement serveur rsyslog
- [x] **supervision** : Installation application Flask
- [x] **client** : Installation outils de test
- [x] **docker_compose** : Orchestration complète

### ✅ Playbooks Ansible

- [x] **install.yml** : Installation Docker
- [x] **deploy.yml** : Déploiement complet
- [x] **rules_update.yml** : Modification dynamique des règles
- [x] **tests.yml** : Tests automatiques + vérification logs

### ✅ Automatisation complète

- [x] Déploiement sans intervention manuelle
- [x] Configuration automatique via Ansible
- [x] Tests automatisés
- [x] Mise à jour dynamique des règles

## 🎯 Fonctionnalités supplémentaires

- Interface web moderne et responsive
- API REST pour intégration
- Actualisation automatique des logs (5 secondes)
- Statistiques en temps réel
- Parsing intelligent des logs UFW
- Support multi-réseaux Docker

## 📊 Architecture détaillée

```
┌─────────────────────────────────────────────────────────┐
│                    Machine Virtuelle                    │
│                                                         │
│  ┌──────────┐    ┌──────────────┐    ┌─────────────┐ │
│  │ Firewall │───▶│ Logcollector │───▶│ Supervision │ │
│  │  (UFW)   │    │  (rsyslog)   │    │   (Flask)   │ │
│  └────┬─────┘    └──────────────┘    └─────────────┘ │
│       │                                               │
│       │                                               │
│  ┌────▼─────┐                                         │
│  │  Client  │                                         │
│  │ (tests)  │                                         │
│  └──────────┘                                         │
│                                                         │
│  Réseaux: firewall, logs, supervision, tests          │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Flux de données

1. **Génération de trafic** : Le conteneur client génère du trafic vers le firewall
2. **Filtrage** : UFW applique les règles et génère des logs
3. **Collecte** : rsyslog dans le firewall envoie les logs au logcollector
4. **Stockage** : Le logcollector stocke les logs dans `/var/log/firewall/`
5. **Visualisation** : L'application Flask lit les logs et les affiche
6. **Analyse** : L'utilisateur consulte les statistiques et logs en temps réel

## 🧪 Scénarios de test

### Scénario 1 : Test de blocage
1. Client tente une connexion sur le port 445 (SMB)
2. UFW bloque la connexion
3. Log généré avec action `[UFW BLOCK]`
4. Log apparaît dans la supervision en quelques secondes

### Scénario 2 : Test d'autorisation
1. Client tente une connexion SSH depuis le réseau interne
2. UFW autorise (règle allow from 172.20.0.0/16)
3. Log généré avec action `[UFW ALLOW]`
4. Log visible dans la supervision

### Scénario 3 : Mise à jour dynamique
1. Exécution de `rules_update.yml`
2. Script UFW régénéré avec nouvelles règles
3. Image firewall reconstruite
4. Conteneur redémarré avec nouvelles règles
5. Tests automatiques vérifient le bon fonctionnement

## 📈 Métriques de supervision

L'application de supervision affiche :
- **Total logs** : Nombre total d'événements
- **Tentatives bloquées** : Connexions refusées par UFW
- **Connexions autorisées** : Trafic autorisé
- **IP sources** : Nombre d'adresses IP uniques
- **Détails par log** : IP source, destination, protocole, port, action

## 🔐 Sécurité

- Isolation réseau via Docker networks
- Pare-feu avec règles restrictives
- Protection brute-force sur SSH
- Journalisation complète pour audit
- Pas d'exposition de ports sensibles vers l'extérieur

## 🚀 Déploiement

Le projet peut être déployé en 2 commandes :
```bash
ansible-playbook ansible/playbooks/install.yml
ansible-playbook ansible/playbooks/deploy.yml
```

Tout est automatisé, aucune intervention manuelle requise.

## 📝 Conclusion

Le projet AutoDeploy Firewall répond à 100% aux exigences du cahier des charges :
- ✅ Infrastructure complète avec 4 conteneurs
- ✅ Réseaux Docker dédiés
- ✅ Pare-feu opérationnel avec toutes les règles
- ✅ Centralisation des logs
- ✅ Supervision visuelle
- ✅ Client de test
- ✅ Automatisation complète via Ansible
- ✅ Tests automatisés
- ✅ Mise à jour dynamique des règles

Le projet est prêt pour la démonstration et l'évaluation.



