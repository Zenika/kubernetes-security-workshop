Consulter les ClusterRoleBindings `system:discovery` :

- `kubectl get clusterrolebindings system:discovery`

Vous constaterez qu'il affecte des droits au groupe
`system:unauthenticated`, notamment les non-resource urls `/version` et
`/version/`.

Patchez le ClusterRole system-discovery avec celui-ci
`system-discovery-role.yaml` :

- `kubectl apply -f system-discovery-role.yaml`
