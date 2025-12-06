# Guide de démarrage rapide - AutoDeploy Firewall

> ⚠️ **Pour un guide détaillé pas à pas, consultez [INSTALLATION.md](INSTALLATION.md)**

## 🚀 Démarrage en 3 étapes

### Étape 1 : Installation de Docker
```bash
ansible-playbook ansible/playbooks/install.yml
```

### Étape 2 : Déploiement complet
```bash
ansible-playbook ansible/playbooks/deploy.yml
```

### Étape 3 : Accéder à la supervision
Ouvrez votre navigateur : **http://localhost:5000**

## 🧪 Tester le pare-feu

### Depuis le conteneur client
```bash
docker exec -it client bash
```

### Commandes de test
```bash
# Scan de ports
nmap -p 22,80,443,445 firewall

# Test SSH
nc -zv firewall 22

# Test HTTP (devrait être bloqué)
curl http://firewall:80

# Test SMB (devrait être bloqué)
nc -zv firewall 445
```

## 📊 Voir les logs

```bash
# Logs en temps réel
docker-compose logs -f

# Logs du firewall uniquement
docker-compose logs -f firewall

# Logs dans le collecteur
docker exec logcollector tail -f /var/log/firewall/*.log
```

## 🔧 Mettre à jour les règles UFW

```bash
ansible-playbook ansible/playbooks/rules_update.yml
```

## ✅ Tests automatiques

```bash
ansible-playbook ansible/playbooks/tests.yml
```

## 🛑 Arrêter l'infrastructure

```bash
docker-compose down
```

## 🔄 Redémarrer

```bash
docker-compose restart
```

## 📝 Vérifier les règles UFW

```bash
docker exec firewall ufw status verbose
```



