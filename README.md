# kubernetes-security-workshop

Le but du workshop est d'apprendre comment sécuriser son cluster kubernetes par la pratique. Nous allons aborder les sujets suivant :
 - Les bonnes pratiques de sécurité des images de conteneur
 - La gestion des droits d'accès à l'API Kubernetes avec le RBAC
 - Cloisonner les composants d'un cluster Kubernetes
 - La mise à jour d'un cluster suite à une CVE
 - Détecter des comportements anormaux au run

Le workshop commencera d'abord par une présentation générale des différents concepts abordés avant de vous laisser avancer à votre rythme.

Pour pouvoir continuer à avancer même si une étape est problématique, nous vous fournissons les solutions de chacune des étapes.

### Connexion à l'espace de travail

Au début du workshop, nous vous avons donné les informations pour vous connecter. La commande à lancer pour se connecter :

```bash
ssh <user>@<host>
```

### Construire des images de conteneurs en appliquant les bonnes pratiques de sécurité

La sécurité d'un cluster Kubernetes commence par la sécurité des applications. Nous allons illustrer comment sécuriser une application vulnérable à une faille publiquement connue. L'exemple utilisé ici est une faille de rails publiée au début de 2019 (https://nvd.nist.gov/vuln/detail/CVE-2019-5418)

#### Construction et déploiement

Nous vous fournissons déjà l'application bootstrapée, le Dockerfile et les descripteurs Kubernetes pour déployer l'application.

Les commandes à lancer :

Construction de l'image :
```bash
docker image build -t eu.gcr.io/<projet>/rails-with-cve:1 .
```

Publication de l'image :
```bash
docker image push eu.gcr.io/<projet>/rails-with-cve:1
```

Déploiement de l'image :
```bash
kubectl apply -f k8s
```

#### Exploitation de la faille

Une fois l'application démarrée, vous pouvez la requêter normalement pour obtenir le README du projet :

```bash
# Pour obtenir l'ip des noeuds
kubectl get nodes -o wide
# Utiliser une external ip
curl <node-external-ip>/rails/chybeta
```

Mais avec la faille présente dans cette version de rails, nous pouvons facilement récupérer n'importe quel fichier du conteneur !

```bash
curl <node-external-ip>/rails/chybeta -H 'Accept: ../../../../../../../../../../etc/shadow{{'
```

Vous pouvez retrouver une explication de la faille : https://chybeta.github.io/2019/03/16/Analysis-for%E3%80%90CVE-2019-5418%E3%80%91File-Content-Disclosure-on-Rails/

Cette faille peut être exploitée aussi pour ouvrir un shell à distance dans le conteneur, un exemple d'exploit: https://github.com/mpgn/Rails-doubletap-RCE

Pour mitiger le problème, il y a deux étapes.

#### Changement d'utilisateur

La première étape consiste à changer l'utilisateur avec lequel s'exécute l'application pour limiter les accès fichiers possible via l'application. 

Rajouter l'instruction USER a l'image Docker (ref: https://docs.docker.com/engine/reference/builder/#user)
```Dockerfile
USER rails
```
Modifier l'instrution COPY pour refléter ce changement de droit (ref: https://docs.docker.com/engine/reference/builder/#copy)

Pour rappel, pour créer un utilisateur sous debian, il faut executer la commande suivante : 
```bash
groupadd --gid 1000 rails && useradd --uid 1000 --gid rails --shell /bin/bash --create-home rails
```

Construire, publier et redéployer l'image avec le tag :
```
eu.gcr.io/<projet>/rails-with-cve:2
```

Une fois la nouvelle version de l'application déployée, le curl précédent ne fonctionne plus pour récupérer `/etc/shadow` :
```bash
curl <node-external-ip>/rails/chybeta -H 'Accept: ../../../../../../../../../../etc/shadow{{'
```

Mais on peut toujours requêter d'autres fichiers :
```bash
curl <node-external-ip>/rails/chybeta -H 'Accept: ../../../../../../../../../../demo/Gemfile{{'
```

#### Mise à jour des dépendances

La seconde étape va être de mettre à jour la version de rails qui contient le fix de la CVE. Mettre à jour le fichier Gemfile avec une version fixée de rails.

Construire, publier et redéployer l'image avec le tag :
```
eu.gcr.io/<projet>/rails-without-cve:1
```

Une fois la nouvelle version de l'application déployée, le curl précédent ne fonctionne plus pour récupérer `/etc/shadow` :
```bash
curl <node-external-ip>/rails/chybeta -H 'Accept: ../../../../../../../../../../demo/Gemfile{{'
```

#### Conclusion

La sécurité se joue a plusieurs niveaux pour une application :
 - Son code
 - Ses dépendances
 - L'utilisateur avec lequel tourne l'application

Nous n'avons illustré ici que les deux derniers points, la sécurisation du code reste à faire côté développement :)

Vous pouvez retrouver d'autres pratiques pour améliorer la sécurité de vos images de conteneurs : https://res.cloudinary.com/snyk/image/upload/v1551798390/Docker_Image_Security_Best_Practices_.pdf

### 02 : Bien exploiter le RBAC
### 03 : Cloisonner les composants d’un cluster
 - Quota / limit
 - Network policies
 - Pod security policies

### 04 : détecter des comportements non souhaités au runtime 
 - Opa (policy, only signed images?)
 - Falco

### 05 : Comprendre l’importance des mises à jours suite à une CVE
 - Exploiter une cve fixée (maj cluster)
