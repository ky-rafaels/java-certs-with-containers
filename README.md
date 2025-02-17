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

Create password secret to be used for Java keystore

```bash
kubectl create secret generic keystore-pass --from-literal=password=HellYes123 -n default
```

## Examples

### JKS Certificates
```bash
# Apply the self-signed ca certificate 
kubectl apply -f k8s/cert-manager/cluster-issuer.yaml
# Then apply the wildcard certificate
kubectl apply -f k8s/cert-manager/wildcard.yaml
```

You should now have CA cert bundle along with wildcard certificate secrets
```bash
❯ kubectl get secret -n default
NAME            TYPE                DATA   AGE
keystore-pass   Opaque              1      7m4s
wildcard-tls    kubernetes.io/tls   5      6m38s

....

❯ kubectl get secret -n cert-manager
NAME                                  TYPE                 DATA   AGE
cert-manager-webhook-ca               Opaque               3      4d5h
root-secret                           kubernetes.io/tls    3      22m
sh.helm.release.v1.cert-manager.v1    helm.sh/release.v1   1      4d5h
sh.helm.release.v1.trust-manager.v1   helm.sh/release.v1   1      4d5h
trust-manager-tls                     kubernetes.io/tls    3      4d5h
```

Next let's build our Java sample app and mount our secrets in a Java Keystore

```bash
docker build -t java-app:v1.0 .


### Trust bundles
