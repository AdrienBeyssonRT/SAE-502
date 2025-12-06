# 🔧 Correction du conteneur logcollector

## ❌ Problème identifié

Le conteneur `logcollector` redémarre en boucle avec l'erreur :
```
rsyslogd: $WorkDirectory: /var/lib/rsyslog can not be accessed, probably does not exist
```

## ✅ Solutions appliquées

### 1. Dockerfile du logcollector
- ✅ Ajout de la création du répertoire `/var/lib/rsyslog` dans le Dockerfile
- ✅ Définition des permissions appropriées

### 2. Script entrypoint.sh du logcollector
- ✅ Création des répertoires au démarrage (sécurité supplémentaire)
- ✅ Utilisation de `exec rsyslogd -n` pour que rsyslog soit le processus principal
- ✅ Gestion d'erreur améliorée

### 3. Script entrypoint.sh du firewall
- ✅ Création du répertoire `/var/lib/rsyslog` pour éviter le même problème

## 🔄 Pour appliquer les corrections

Après avoir modifié les fichiers, vous devez reconstruire les images :

```bash
# Arrêter les conteneurs
docker-compose down

# Reconstruire les images
docker-compose build --no-cache logcollector firewall

# Redémarrer
docker-compose up -d
```

Ou via Ansible :

```bash
ansible-playbook ansible/playbooks/deploy.yml
```

## ✅ Vérification

Après redémarrage, vérifiez que le conteneur logcollector fonctionne :

```bash
docker ps | grep logcollector
# Devrait afficher "Up" au lieu de "Restarting"

docker logs logcollector
# Ne devrait plus afficher d'erreurs sur /var/lib/rsyslog
```

