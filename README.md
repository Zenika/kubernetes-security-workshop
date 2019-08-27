# kubernetes-security-workshop

Le but du workshop est d'apprendre comment sécuriser son cluster kubernetes par la pratique.

Le workshop commencera d'abord par une présentation générale des différents concepts abordés avant de vous laisser avancer à votre rythme.

Pour pouvoir continuer à avancer même si une étape est problématique, nous vous fournissons les solutions de chacune des étapes.

### 01 : Construire des images de conteneurs en appliquant les bonnes pratiques de sécurité


Demo of CVE-2019-5418 (https://github.com/mpgn/CVE-2019-5418)
```
docker image build -t rails-with-cve .
docker container run -d --rm --name rails-with-cve -p 3000:3000 rails-with-cve
curl localhost:3000/chybeta
curl localhost:3000/chybeta -H "Accept: ../../../../../../../../../../root/.bash_history{{"
docker container stop rails-with-cve
```
Step add USER
```
docker image build -t rails-with-user -f DockerfileWithUser .
docker container run -d --rm --name rails-with-user -p 3000:3000 rails-with-user
curl localhost:3000/chybeta
curl localhost:3000/chybeta -H "Accept: ../../../../../../../../../../root/.bash_history{{"
curl localhost:3000/chybeta -H "Accept: ../../../../../../../../../../rails/.bash_history{{"
```
Step update rails
```
Update rails in 5.2.2 in Gemfile and delete Gemfile.lock
docker image build -t rails-without-cve -f DockerfileWithUser .
docker container run -d --rm --name rails-without-cve -p 3000:3000 rails-without-cve
curl localhost:3000/chybeta
curl localhost:3000/chybeta -H "Accept: ../../../../../../../../../../rails/.bash_history{{"
```

Cheatsheet : https://res.cloudinary.com/snyk/image/upload/v1551798390/Docker_Image_Security_Best_Practices_.pdf

### 02 : Cloisonner les composants d’un cluster
 - Quota / limit
 - Network policies
 - Pod security policies

### 03 : Bien exploiter le RBAC

### 04 : Comprendre l’importance des mises à jours suite à une CVE
 - Exploiter une cve fixée (maj cluster)

### 05 : détecter des comportements non souhaités au runtime 
 - Opa (policy, only signed images?)
 - Falco 
