# kubernetes-security-workshop

Le but du workshop est d'apprendre comment sécuriser son cluster Kubernetes par la pratique. Nous allons aborder les sujets suivant :

- [Les bonnes pratiques de sécurité des images de conteneur](https://github.com/ebriand/kubernetes-security-workshop#01--construire-des-images-de-conteneurs-en-appliquant-les-bonnes-pratiques-de-s%C3%A9curit%C3%A9)
- [Cloisonner les composants d'un cluster Kubernetes](https://github.com/ebriand/kubernetes-security-workshop#02--cloisonner-les-composants-dun-cluster)
- [La gestion des droits d'accès à l'API Kubernetes avec le RBAC](https://github.com/ebriand/kubernetes-security-workshop#03--bien-exploiter-le-rbac)
- [Limiter les privilèges des conteneurs exécutés sur le cluster](https://github.com/ebriand/kubernetes-security-workshop#04--podsecuritypolicy)
- [La mise à jour d'un cluster suite à une CVE](https://github.com/ebriand/kubernetes-security-workshop#05--comprendre-limportance-des-mises-%C3%A0-jour-suite-%C3%A0-une-cve)
- [Détecter des comportements anormaux au run](https://github.com/ebriand/kubernetes-security-workshop#06--d%C3%A9tecter-des-comportements-non-souhait%C3%A9s-au-runtime)

Le workshop commencera d'abord par une présentation générale des différents concepts abordés avant de vous laisser avancer à votre rythme.

Pour pouvoir continuer à avancer même si une étape est problématique, nous vous fournissons les solutions de chacune des étapes.

## Connexion à l'espace de travail

Au début du workshop, nous vous avons donné les informations pour vous connecter. La commande à lancer pour se connecter :

```bash
ssh ubuntu@<host>
```

Entrez le mot de passe fourni au début du workshop.

Vous avez les 4 machines à disposition :
![Lab infrastructure](images/lab-infrastructure.png)

- Une machine `shell` sur laquelle vous vous connectez par défaut.
  - Sur cette machine sont installés différents outils : `kubectl`, `docker`, `gcloud`
  - Les autres machines sont accessibles directement via `ssh <hostname>`.
    Exemple: `ssh controller`
  - L'énoncé du workshop et les ressources sont déployées dans `/home/ubuntu/kubernetes-security-workshop` via un clone du repository
  - Dans chacune des étapes, vous retrouverez un sous répertoire `solution` si vous avez besoin de vous débloquer.
- Le `controller`, control-plane du cluster Kubernetes
- `worker-0` et `worker-1`, 2 workers du cluster Kubernetes

En interne du cluster les noeuds ont un nommage un peu différent :

- `controller` : `node1`
- `worker-0` : `node2`
- `worker-1` : `node3`

## 01 : Construire des images de conteneurs en appliquant les bonnes pratiques de sécurité

La sécurité d'un cluster Kubernetes commence par la sécurité des applications. Nous allons illustrer comment sécuriser une application vulnérable à une faille publiquement connue. L'exemple utilisé ici est une faille de rails publiée au début de 2019 (<https://nvd.nist.gov/vuln/detail/CVE-2019-5418>)

### Construction et déploiement

Nous vous fournissons déjà l'application bootstrapée, le Dockerfile et les descripteurs Kubernetes pour déployer l'application. Les fichiers sont dans le répertoire `/home/ubuntu/kubernetes-security-workshop/01-docker-images`

Les commandes à lancer :

Construire l'image :

```bash
docker image build -t eu.gcr.io/$PROJECT_ID/rails-with-cve:1 .
```

Publier l'image :

```bash
docker image push eu.gcr.io/$PROJECT_ID/rails-with-cve:1
```

Corriger le nom de l'image dans le fichier de deploiement `k8s/01_deployment.yaml`, remplacer PROJECT_ID par la valeur donnée par:

```bash
echo $PROJECT_ID
```

Deployer l'application dans Kubernetes :

```bash
kubectl apply -f k8s
```

### Exploitation de la faille

Une fois l'application démarrée, vous pouvez la requêter normalement pour obtenir le README du projet :

```bash
# Pour obtenir l'ip des noeuds
kubectl get nodes -o wide
# Obtenir le port de l'ingress controller
export INGRESS_PORT=$(kubectl get svc -n kube-system traefik-ingress-service -o jsonpath={.spec.ports[0].nodePort})
# Utiliser une ip d'un node
curl 10.132.0.22:$INGRESS_PORT/rails/chybeta
```

Mais avec la faille présente dans cette version de rails, nous pouvons facilement récupérer n'importe quel fichier du conteneur !

```bash
curl 10.132.0.22:$INGRESS_PORT/rails/chybeta -H 'Accept: ../../../../../../../../../../etc/shadow{{'
```

Vous pouvez retrouver une explication de la faille : <https://chybeta.github.io/2019/03/16/Analysis-for%E3%80%90CVE-2019-5418%E3%80%91File-Content-Disclosure-on-Rails/>

Cette faille peut être exploitée aussi pour ouvrir un shell à distance dans le conteneur, un exemple d'exploit: <https://github.com/mpgn/Rails-doubletap-RCE>

Pour mitiger le problème, il y a deux étapes.

### Changement d'utilisateur

La première étape consiste à changer l'utilisateur avec lequel s'exécute l'application pour limiter les accès fichiers possibles via l'application.

Rajouter l'instruction USER à l'image Docker (ref: <https://docs.docker.com/engine/reference/builder/#user>)

```Dockerfile
USER rails:rails
```

Modifier l'instruction COPY pour refléter ce changement de droit (ref: <https://docs.docker.com/engine/reference/builder/#copy>)

Pour rappel, pour créer un utilisateur sous debian, il faut exécuter la commande suivante :

```bash
groupadd --gid 1000 rails && useradd --uid 1000 --gid rails --shell /bin/bash --create-home rails
```

Construire, publier et redéployer l'image avec le tag :

```txt
eu.gcr.io/$PROJECT_ID/rails-with-cve:2
```

Une fois la nouvelle version de l'application déployée, le curl précédent ne fonctionne plus pour récupérer `/etc/shadow` :

```bash
curl 10.132.0.22:$INGRESS_PORT/rails/chybeta -H 'Accept: ../../../../../../../../../../etc/shadow{{'
```

Mais on peut toujours requêter d'autres fichiers :

```bash
curl 10.132.0.22:$INGRESS_PORT/rails/chybeta -H 'Accept: ../../../../../../../../../../demo/Gemfile{{'
```

À noter que cette pratique permet de mitiger d'éventuelles autres failles qui n'auraient pas encore de correctifs.

### Mise à jour des dépendances

La seconde étape va être de mettre à jour la version de rails qui contient le fix de la CVE. Mettre à jour le fichier Gemfile avec une version fixée de rails.

Construire, publier et redéployer l'image avec le tag :

```txt
eu.gcr.io/$PROJECT_ID/rails-without-cve:1
```

Une fois la nouvelle version de l'application déployée, le curl précédent ne fonctionne plus pour récupérer des fichiers du conteneur indépendamment de leur propriétaire :

```bash
curl 10.132.0.22:$INGRESS_PORT/rails/chybeta -H 'Accept: ../../../../../../../../../../demo/Gemfile{{'
```

Une fois le test effectué, supprimer le déploiement.

```bash
kubectl delete -f k8s
```

### Conclusion

La sécurité se joue a plusieurs niveaux pour une application :

- Son code
- Ses dépendances
- L'utilisateur avec lequel tourne l'application

Nous n'avons illustré ici que les deux derniers points, la sécurisation du code reste à faire côté développement :)

Vous pouvez retrouver d'autres pratiques pour améliorer la sécurité de vos images de conteneurs : <https://res.cloudinary.com/snyk/image/upload/v1551798390/Docker_Image_Security_Best_Practices_.pdf>

## 02 : Cloisonner les composants d’un cluster

Lorsqu'on utilise Kubernetes, les
[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#)
permettent d'organiser et de partager les ressources disponibles sur un cluster
Kubernetes entre plusieurs équipes.
Afin que cette cohabition se passe au mieux, l'API Kubernetes expose des
ressources utilisées pour limiter et maîtriser ce que chaque équipe peut faire.

### 02.01 : Quotas / Limits

Une première étape consiste à limiter les ressources utilisables dans un
Namespace. Cela permet de se prémunir d'une utilisation excessive de ressources
dans ce Namespace sans nuire aux autres Namespaces dans le cas d'une
manipulation accidentelle (application qui surconsomme des ressources en cas de
problème) ou d'une attaque extérieure (récupération d'un token d'accès au
cluster).

Un exemple est disponible à déployer sur votre cluster :
`kubectl apply -f 02-partition/01-quota/malicious-deployment.yml`

Ce déploiement va créer un Pod qui consommera toute la mémoire du noeud
`node3` / `worker-1`.

- Lancez `kubectl get nodes -w`

Au bout de quelques instants vous verrez :
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
mécanisme, vous pouvez consulter la documentation officielle [ici](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/).

Néanmoins, ce mécanisme seul ne suffit pas. En effet il est toujours possible
de créer des Pods sans déclarer les `limits` associées.
Les objets `LimitRange` permettent de s'assurer que dans un Namespace donné,
tous les objets créés définiront les limites de ressources tout en respectant
des valeurs minimum et maximum.

En vous inspirant de la 
[documentation](https://kubernetes.io/docs/concepts/policy/limit-range/),
créez une `LimitRange` afin de s'assurer que lorsqu'un Pod est créé il ne
puisse pas prendre toutes les ressources disponibles.
Positionnez une valeur par défaut à `memory: "512Mi"` et `cpu: "10m"` pour la limite.

Recréez le Pod avec la commande précédente, et vérifiez que cette fois ci il est
supprimé lorsqu'il occupe trop de ressources.

Malheureusement, même ainsi, il est toujours possible d'occuper toutes les
ressources du cluster en augmentant le nombre d'instances du Pod qui tournent
en même temps.
Faites le test en lançant la commande (définissez une valeur suffisament élevée
pour occuper toute la mémoire) :  
`kubectl scale --replicas=20 deploy/exhauster`

À nouveau, lancez `kubectl get nodes -w`

Et attendez quelques minutes de voir :
`node3   NotReady   <none>   15h   v1.15.3`

Il est également possible que le noeud reste disponible mais que les Pods
restent en Pending. L'effet est le même pour les équipes qui partageraient
ce cluster : les ressources ne sont plus disponibles.

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
`kubectl scale --replicas=20 deploy/exhauster`

### 02.02 : NetworkPolicy

Une seconde étape de cloisonnement est d'utiliser les NetworkPolicies. Elles vont permettre d'autoriser ou d'interdire les communications réseaux entrantes ou sortantes des pods.

:warning: Les NetworkPolicies nécessitent un network addon compatible :warning:

Nous allons utiliser une application 3 tiers traditionnelle et déclarer les règles suivantes :

- Le front peut communiquer avec le backend
- Le backend peut communiquer avec la base de données

Déployer l'application:
`kubectl apply -f 02-partition/02-network-policies/application.yaml`

Sans NetworkPolicies, tout Pod peut communiquer avec un autre:

```bash
kubectl get pods -n app
kubectl exec -n app -it <anypod> bash
curl frontend
curl backend
(printf "PING\r\n";) | nc redis 6379
```

Appliquons une première NetworkPolicy pour limiter l'accès à la base de données:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: app
  name: backend-redis-only-policy
spec:
  podSelector:
    matchLabels:
      app: redis
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
```

Essayez de nouveau de faire le ping vers redis depuis le frontend, celui-ci ne devrait plus fonctionner.
Créez les NetworkPolicies suivantes:

- Autoriser la communication vers le Pod backend seulement depuis le Pod frontend
- Refuser toute communication vers le Pod frontend
- Refuser la communication depuis le Pod frontend vers internet

Pour vous aider :

- La documentation des NetworkPolicies : <https://kubernetes.io/docs/concepts/services-networking/network-policies/>
- Des exemples de NetworkPolicies : <https://github.com/ahmetb/kubernetes-network-policy-recipes>

Pour tester que les NetworkPolicies sont correctes:

- Dans le Pod redis : `curl frontend`
- Dans le Pod frontend : `(printf "PING\r\n";) | nc redis 6379`
- Dans le Pod frontend : `curl google.fr`

Grâce aux NetworkPolicies, vous pouvez donc :

- Maitriser les flux entre vos applications pour vous prémunir d'erreurs éventuelles
- Limiter l'impact d'une intrusion en limitant les appels réseaux possibles

Pour aller plus loin, vous pouvez regarder le network addon Cilium qui permet d'avoir des CiliumNetworkPolicies qui vont vous permettre de limiter des accès de manière plus fine comme par exemple définir à quelle ressource REST un Pod peut accéder. Plus d'informations : <https://cilium.io/blog/2018/09/19/kubernetes-network-policies/>

## 03 : Bien exploiter le RBAC

Lors des interactions avec un cluster Kubernetes, toutes les requêtes sont
authentifiées :

- les requêtes effectuées depuis votre poste utilisent un compte associé à un certificat.
  Vous pouvez le consulter à l'aide de la commande suivante :
  `grep client-certificate-data ~/.kube/config | awk '{ print $2 }' | base64 -d | openssl x509 -in - -noout -text | grep "Subject:"`
- les requêtes effectuées dans le cluster sont réalisées par des
  [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
  Pour en savoir plus sur les ServiceAccount vous pouvez également consulter
  [cette page](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

Afin de s'assurer qu'une requête est autorisée sur le cluster, Kubernetes
utilise le principe de Role-Based Access Control (RBAC).

Un rôle donne des droits sur les ressources de l'API (lecture, modification, ...).

L'action est autorisée si au moins un rôle donne les droits nécessaires à
l'utilisateur sur la ressource concernée.

Exemple de rôle permettant de consulter les `Namespace`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: namespace-reader
rules:
- apiGroups: [""]
  resources: ["namespace"]
  verbs: ["get", "watch", "list"]
```

Exemple d'affectation du rôle à un utilisateur:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-namespace
subjects:
- kind: User
  name: "alice@example.com"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-reader
  apiGroup: rbac.authorization.k8s.io
```

Certaines ressources sont transverses au cluster, elles sont :

- gérées via les `ClusterRole`
- attribuées via les `ClusterRoleBinding`

Certaines ressources sont cloisonnées par Namespace, elles sont :

- gérées via les `Role`
- attribuées via les `RoleBinding`

Trouvez comment le rôle `cluster-admin` est associé aux requêtes effectuées via
`kubectl` depuis la machine `shell`

Afin de simplifier les interactions avec l'API Server du cluster Kubernetes,
par défaut un ServiceAccount est créé pour chaque Namespace.
Les informations permettant de se connecter à l'API Server
(token, cacert, ...) sont montées par défaut pour tous les Pods dans le
répertoire : `/var/run/secrets/kubernetes.io/serviceaccount`

Certains composants déployés sur Kubernetes ont besoin d'autorisations
particulières pour fonctionner et utilisent ces Service Account associés à des
droit particuliers :

- Les IngressControllers ont besoin d'avoir accès aux ressources de type
  Ingress
  (voir [Traefik RBAC Configuration](https://docs.traefik.io/user-guide/kubernetes/#role-based-access-control-configuration-kubernetes-16-only)).
- Helm utilise un ServiceAccount dédié à Tiller qui a des droits étendus afin
  de pouvoir déployer sur le cluster
  (voir [Tiller RBAC Configuration](https://github.com/helm/helm/blob/master/docs/rbac.md#role-based-access-control))
- ...

Il est nécessaire d'être particulièrement vigilant avec les droits associés aux
Service Account, car leur utilisation peut donner un accès étendu au Cluster.

Pour expérimenter ces configurations, déployez les fichiers présents dans le
répertoire `initial`.

Deux Pods seront créés `shell-pod` et `podreader`.

Ces deux Pods utilisent le Service Account `default` du Namespace `default` et
par défaut nous avons donné les droits à ces Pods de lister tous les Pods du
cluster.
Vous pouvez le tester en lançant les commande :

`kubectl exec -it podreader kubectl get pods`

`kubectl exec -it shell-pod kubectl get pods`

L'objectif est de faire en sorte que seul le Pod `podreader` ait les droits
pour afficher les Pods du cluster.

- Créez un descripteur pour un Service Account `rbac` dans le Namespace du même
  nom. Aidez vous de
  [cette documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-multiple-service-accounts)
- Modifiez les descripteurs pour faire en sorte que le Pod `podreader` utilise
  ce ServiceAccount et ait les droits de lister les Pods du cluster alors que
  `shell-pod` ne les ait plus. Pour utiliser le ServiceAccount, le Pod devra
  être créé dans le même Namespace.

Il est nécessaire d'être extrêmement vigilant avec les droits qui sont
attribués au travers du RBAC. En particulier sur les ressources critiques
du cluster du point de vue de la sécurité :

- LimitRange, Quotas, PodSecurityPolicy, Role, RoleBinding, ClusterRole, ...

## 04 : PodSecurityPolicy

Lors de la première étape, nous avons vu qu'il n'était pas souhaitable de
laisser les utilisateurs lancer des conteneurs en tant qu'utilisateur `root`.

Il est possible, et nécessaire de sensibiliser les équipes à ce sujet, mais il
est également possible d'activer un mécanisme de Kubernetes permettant de
s'assurer que les conteneurs ne fonctionnent pas avec l'utilisateur `root`
ainsi que d'autres contraintes de sécurité.

Un premier mécanisme, nommé
[SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
permet d'ajouter des informations aux Pods et Deployment afin, notamment, de
préciser l'utilisateur avec lequel le conteneur s'exécutera et autres
contraintes.

Exemple de Pod avec un `SecurityContext` :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-2
spec:
  containers:
  - name: sec-ctx-demo-2
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
```

Un second mécanisme, l'[Admission Controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) s'appuie sur un plugin de Kubernetes qui va valider et
autoriser ou interdire les requêtes de création des Pods :

![Admission controller phases](images/admission-controller-phases.png)

L'admission plugin est nommé comme la ressource qu'il exploite :
[PodSecurityPolicy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)

Vous trouverez ci-dessous un exemple de `PodSecurityPolicy` qui interdit :

- d'exécuter des conteneurs en mode privilégié
- de monter des répertoires de l'hôte dans les conteneurs

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: example
spec:
  privileged: false  # Don't allow privileged pods!
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
    # Don't allow to mount hostPath volume types and expose host dirs in
    # containers
    # - 'hostPath'
```

Ces plugins sont activables et désactivables au lancement de l'API Server
Kubernetes.
Malheureusement `PodSecurityPolicy` n'est pas activé par défaut et il va falloir
l'activer avant de pouvoir l'utiliser pour sécuriser votre cluster.
_Attention_ néanmoins, une fois que ce plugin est activé, il n'est plus
possible de créer de Pod sans avoir défini les droits pour autoriser
l'utilisation d'une `PodSecurityPolicy` validant la création du Pod.

Commencez par déployer une `PodSecurityPolicy` permissive et autoriser
le service account par défaut du Namespace `kube-system` à l'utiliser.
En effet, il s'agit de l'espace du cluster réservé au déploiement des
conteneurs utilisés pour l'administration du cluter.

- `kubectl apply -f 04-psp/kube-system-psp.yaml`
- `kubectl apply -f 04-psp/default-psp.yaml`

Connectez-vous en ssh au serveur qui héberge le control-plane du cluster.

- `ssh controller`

En tant qu'utilisateur `root`, éditez le fichier
`/etc/kubernetes/manifests/kube-apiserver.yaml`

Remplacer la ligne
`- --enable-admission-plugins=NodeRestriction`
En
`- --enable-admission-plugins=NodeRestriction,PodSecurityPolicy`

Sauvegardez le fichier

L'API Server doit se relancer et cela peut nécessiter quelques minutes.
En attendant vous pouvez avoir un message du type :

```bash
ubuntu@shell:~$ kubectl get pods
The connection to the server 10.132.0.21:6443 was refused - did you specify the right host or port?
```

Une fois l'API Server redémarré, essayer de re-déployer la version vulnérable
de la première application.
Vous devriez constater que le Pod ne démarre pas.
Essayons de savoir pourquoi avec la commande suivante :
`kubectl describe pod <nom du pod>`

Vous devriez voir un message du type :
`Warning  Failed     2m27s (x8 over 3m50s)  kubelet, node2     Error: container has runAsNonRoot and image will run as root`

En vous aidant de la documentation, modifiez le déploiement pour y ajouter un
SecurityContext à la définition des Pods afin que les conteneurs fonctionnent
avec un autre utilisateur que `root` et puissent être créés et démarrés.

Une fois ces tests réalisés :

- Supprimez le déploiement
- Désactivez l'admission plugin `PodSecurityPolicy`

## 05 : Comprendre l’importance des mises à jour suite à une CVE

Afin de s'assurer que le Cluster Kubernetes déployé ne comporte pas de failles
liées à des erreurs de configuration ou des
[CVE](https://fr.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures), il
existe des outils permettant de le scanner.

L'outil que nous allons mettre en oeuvre ici est
[kube-hunter](https://github.com/aquasecurity/kube-hunter)
d'[Aqua Security](https://www.aquasec.com/).

Exemple de résultat :

```txt
Vulnerabilities
+------------------+----------------------+----------------------+----------------------+----------+
| LOCATION         | CATEGORY             | VULNERABILITY        | DESCRIPTION          | EVIDENCE |
+------------------+----------------------+----------------------+----------------------+----------+
| 10.132.0.21:6443 | Information          | K8s Version          | The kubernetes       | v1.15.3  |
|                  | Disclosure           | Disclosure           | version could be     |          |
|                  |                      |                      | obtained from the    |          |
|                  |                      |                      | /version endpoint    |          |
+------------------+----------------------+----------------------+----------------------+----------+
```

Cet outil peut fonctionner de 2 manières :

- Depuis l'extérieur, en utilisant une image Docker :
  `docker container run -it --rm aquasec/kube-hunter --remote 10.132.0.21`

Vous pouvez alors consulter directement les résultats.
Il est également possible de scanner tout un range d'adresses réseau pour
trouver tous les composants susceptibles d'être en écoute :
`docker container run -it --rm aquasec/kube-hunter --cidr 10.132.0.0/24`

- Depuis l'intérieur du cluster, sous forme de Job Kubernetes, voir
  `06-scan-cluster/kube-hunter-job.yaml`

Dans ce cas là, vous pouvez consulter l'état du Job avec la commande :
`kubectl describe job kube-hunter`
Et en consulter les logs avec la commande :
`kubectl logs <pod name>`

- Quels sont les problèmes détectés depuis l'extérieur ?
- Sauriez-vous les résoudre ?

Pour information, lorsqu'une requête est faite sans authentification, elle est
associée au groupe `system:unauthenticated`.

## 06 : détecter des comportements non souhaités au runtime

Dans les parties précédentes, nous avons vu comment configurer un cluster pour pouvoir mitiger des manipulations accidentelles ou volontaires qui pourraient porter atteinte à son intégrité.

Mais comment détecter un comportement lorsque le cluster fonctionne ? Nous allons utiliser un outil de détection d'intrusion et de comportement anormal.
[Falco](https://falco.org/) est un outils de la CNCF qui permet de faire cela.

Pour l'installer:

```bash
helm install --name falco stable/falco
```

Une fois installé, Falco va auditer en permanence votre cluster. De base un ensemble de règles sont activées pour surveiller le comportement de votre cluster.

Les règles par défaut se trouvent ici : <https://github.com/falcosecurity/falco/blob/dev/rules/falco_rules.yaml>

- Trouver la règle par défaut concernant le spawn de terminal
- Instancier un terminal dans un pod
- Regarder les logs de falco pour trouver l'événement déclenché
- Déclencher un événement de niveau ERROR

Falco ne fait que de l'audit. Une fois cet outil mis en place, on peut le configurer pour publier ses événements en format JSON. En envoyant ces événements dans une queue et en ayant une fonction qui réagit à ces événements, nous pouvons déclencher une action.
Par exemple: effacer un pod si un shell est ouvert. Vous pouvez retrouver un exemple de mise en place : <https://github.com/falcosecurity/kubernetes-response-engine>
