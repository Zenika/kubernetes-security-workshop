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

La première étape consiste à changer l'utilisateur avec lequel s'exécute l'application pour limiter les accès fichiers possibles via l'application. 

Rajouter l'instruction USER à l'image Docker (ref: https://docs.docker.com/engine/reference/builder/#user)
```Dockerfile
USER rails
```
Modifier l'instruction COPY pour refléter ce changement de droit (ref: https://docs.docker.com/engine/reference/builder/#copy)

Pour rappel, pour créer un utilisateur sous debian, il faut exécuter la commande suivante : 
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
À noter que cette pratique permet de mitiger d'éventuelles autres failles qui n'auraient pas encore de correctifs.
#### Mise à jour des dépendances

La seconde étape va être de mettre à jour la version de rails qui contient le fix de la CVE. Mettre à jour le fichier Gemfile avec une version fixée de rails.

Construire, publier et redéployer l'image avec le tag :
```
eu.gcr.io/<projet>/rails-without-cve:1
```

Une fois la nouvelle version de l'application déployée, le curl précédent ne fonctionne plus pour récupérer des fichiers du conteneur indépendamment de leur propriétaire :
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

### 02 : Cloisonner les composants d’un cluster

Lorsqu'on utilise Kubernetes, les 
[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#)
permettent d'organiser et de partager les ressources disponibles sur un cluster
kubernetes entre plusieurs équipes.
Afin que cette cohabition se passe au mieux, l'API Kubernetes expose des
ressources utilisées pour limiter et maîtriser ce que chaque équipe peut faire.

#### 02.01 : Quotas / Limits

Une première étape consiste à limiter les ressources utilisables dans un
Namespace. Cela permet de se prémunir d'une utilisation excessive de ressources
dans ce Namespace sans nuire aux autres Namespaces dans le cas d'une
manipulation accidentelle (application qui surconsomme des ressources en cas de
problème) ou d'une attaque extérieure (récupération d'un token d'accès au
cluster).

Un exemple est disponible à déployer sur votre cluster :
`kubectl apply -f 02-partition/01-quota/malicious-deployment.yml`

Ce déploiement va créer un Pod qui consommera toutes la mémoire du noeud
`node3`.
- Lancez `kubectl get nodes -w`

Au bout de quelques minutes vous verrez :
`node3   NotReady   <none>   15h   v1.15.3`

L'ensemble de la mémoire disponible sur ce noeud a été consommé et il n'est
plus disponible.

Nous allons voir comment éviter ce type de comportement en définissant des
limites de ressources disponibles pour les Pods et leurs Containers. Mais avant
tout nous allons supprimer cette application.

- `kubectl delete deployment exhauster`

Et relancer le noeud afin de le réparer (il doit repasser en Ready) :

- `gcloud compute instances reset worker-1`

Avec Kubernetes, comme avec Docker, il est possible de définir des limites
de ressources affectées aux conteneurs. Pour plus de renseignements sur ce 
mécanisme, vous pouvez consulter la docupmentation officielle [ici](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/).

Néanmoins, ce mécanisme seule ne suffit pas. En effet il est toujours possible
de créer des Pods sans déclarer les `limits` associées.
Les objets `LimitRange` permettent de s'assurer que dans un Namespace donné,
tous les objets créés définiront les limites de ressources tout en respectant
des valeurs minimum et maximum.

Créez une `LimitRange` afin de s'assurer que lorsqu'un Pod est créé il ne
puisse pas prendre toutes les ressources disponibles.

Recréez le Pod avec la commande ci-après, et vérifiez que cette fois ci il est
supprimé lorsqu'il occupe trop de ressources.

Malheureusement, même ainsi, il est toujours possible d'occuper toutes les
ressources du cluster en augmentant le nombre d'instances du Pod qui tournent
en même temps.
Faites le test en lançant la commande (définissez une valeur suffisament élevée
pour occuper toute la mémoire) :  
`kubectl scale --replicas=10 deploy/exhauster`

À nouveau, lancez `kubectl get nodes -w`

Et attendez quelques minutes de voir :
`node3   NotReady   <none>   15h   v1.15.3`

Nous allons voir comment empêcher la création d'un trop grand nombre de Pods.
Mais avant tout, nous allons supprimer cette application.

- `kubectl delete deployment exhauster`

Et relancer le noeud afin de le réparer (il doit repasser en Ready) :

- `gcloud compute instances reset worker-1`

En vous inspirant des exemples disponibles 
[ici](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/),
créez les Quotas afin d'empêcher que la multiplication des instances 
d'`exhauster` n'occupent toutes les ressources.

Tester votre solution en appliquant à nouveau le déploiement :
`kubectl apply -f 02-partition/01-quota/malicious-deployment.yml`

Et en multipliant le nombre d'instances désirées :
`kubectl scale --replicas=10 deploy/exhauster`

#### 02.02 : NetworkPolicy

#### 02.03 : PodSecurityPolicy

### 03 : Bien exploiter le RBAC

### 04 : détecter des comportements non souhaités au runtime 
 - Opa (policy, only signed images?)
 - Falco

### 05 : Comprendre l’importance des mises à jours suite à une CVE
 - Exploiter une cve fixée (maj cluster)
