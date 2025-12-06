# 🔧 Dépannage - Installation Docker

## ✅ Corrections apportées à install.yml

### Problèmes corrigés :

1. **Variable `ansible_user_id` non définie**
   - ✅ Remplacée par une détection automatique de l'utilisateur
   - ✅ Gestion du cas root vs utilisateur normal

2. **docker-compose non disponible via apt**
   - ✅ Installation via pip en fallback
   - ✅ Support de docker-compose-plugin
   - ✅ Création de lien symbolique si nécessaire

3. **Modules Python non installés**
   - ✅ Vérification après installation
   - ✅ Messages d'erreur plus clairs
   - ✅ Gestion des erreurs avec ignore_errors

4. **Pas de vérification post-installation**
   - ✅ Ajout de vérifications à la fin
   - ✅ Messages de résumé clairs

## 🚀 Utilisation

```bash
# Depuis le répertoire racine du projet
ansible-playbook ansible/playbooks/install.yml
```

## ❌ Si ça ne fonctionne toujours pas

### Problème 1 : "Module docker not found"

**Solution manuelle :**
```bash
pip3 install docker --break-system-packages
```

Puis relancez le playbook.

### Problème 2 : "docker-compose: command not found"

**Solution :**
```bash
# Option 1 : Via pip
pip3 install docker-compose --break-system-packages

# Option 2 : Via plugin Docker
sudo apt install docker-compose-plugin
```

### Problème 3 : "Permission denied" avec Docker

**Solution :**
```bash
# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Se déconnecter et reconnecter, ou :
newgrp docker

# Vérifier
docker ps
```

### Problème 4 : Le service Docker ne démarre pas

**Solution :**
```bash
# Vérifier les logs
sudo journalctl -u docker.service

# Redémarrer
sudo systemctl restart docker

# Vérifier le statut
sudo systemctl status docker
```

### Problème 5 : Erreurs pip avec Python 3.13

**Solution :**
Le playbook utilise maintenant `--break-system-packages` automatiquement.

Si ça ne fonctionne toujours pas :
```bash
# Installer manuellement
pip3 install docker docker-compose --break-system-packages --user

# Ajouter au PATH si nécessaire
export PATH=$PATH:~/.local/bin
```

## 📋 Checklist de vérification

Après l'installation, vérifiez :

```bash
# 1. Docker fonctionne
docker --version

# 2. Docker Compose fonctionne
docker-compose --version
# ou
docker compose version

# 3. Vous pouvez exécuter docker sans sudo
docker ps

# 4. Le service Docker est actif
sudo systemctl status docker
```

## 🔍 Commandes de diagnostic

```bash
# Voir les erreurs Ansible en détail
ansible-playbook ansible/playbooks/install.yml -v

# Mode très verbeux
ansible-playbook ansible/playbooks/install.yml -vvv

# Vérifier la configuration Ansible
ansible-config dump

# Tester la connexion
ansible all -m ping
```

## 💡 Installation manuelle complète (si Ansible échoue)

Si rien ne fonctionne, installez manuellement :

```bash
# 1. Mettre à jour
sudo apt update

# 2. Installer Docker
sudo apt install -y docker.io python3-pip python3-docker

# 3. Installer modules Python
pip3 install docker docker-compose --break-system-packages

# 4. Ajouter utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# 5. Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# 6. Vérifier
docker --version
docker ps
```

Ensuite, vous pouvez passer directement à `deploy.yml` :
```bash
ansible-playbook ansible/playbooks/deploy.yml
```

