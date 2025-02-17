# Examples on providing certificates in containers

## Purpose
Providing trusted CA bundles and certificates when working with microservices can be frustrating. The approach here I'd like to propose is to have only the certificates necessary for providing trust to repositories for installation artifacts when a container is built should be provided at time of container build in say a Dockerfile. All other certificates necessary for trust between services that are environment specific, should be provided via kubernetes CRDs. This provides flexibility for containers to be deployable across environments, easing the promotion between environments, removing redundant build tasks from images, and keeping build repos cleaner.

## Test Evironment Setup

Provision a kind cluster using the script [here](https://github.com/ky-rafaels/kind-cluster)

```bash
git clone https://github.com/ky-rafaels/kind-cluster
cd kind-cluster
./cilium-kind-deploy.sh 1 cluster1 us-east-1 us-east-1a
```

<!-- Install Argo
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
``` -->

Clone this repo 

```bash
git clone git@github.com:ky-rafaels/certs-with-containers.git
cd certs-with-containers
```

<!-- *To retrieve ArgoCD Admin user password*
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
``` -->

### Cert Manager and Trust Manager Setup

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.0 \
  --set crds.enabled=true

helm upgrade trust-manager jetstack/trust-manager \
  --install \
  --namespace cert-manager \
  --wait
```

## Examples

### Trust bundles

### JKS Certificates