# Deploy Jenkins in Kubernetes with Vault Plugin

WIP...

## Requirements

* [Helm](https://helm.sh/docs/intro/install/)
* [`kubectl` CLI installed](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* A Kubernetes cluster running (you can use [Minikube]() for a local cluster)

## Steps

Add Jenkins Helm Chart repo:
```bash
helm repo add https://charts.jenkins.io
```
Now, add also Vault Helm Chart repo:
```bash
helm repo add https://helm.releases.hashicorp.com
```

Create your namespaces for Jenkins and Vault:
```bash
kubectl create ns jenkins
kubectl create ns vault
```

Deploy Jenkins:
```bash
helm install jenkinsci/jenkins -f jenkins_values.yaml -n jenkins
```

Deploy Vault:
```bash
helm install hashicorp/vault --set server.dev.enabled=true -n vault
```

