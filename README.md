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

Viewing our wildcard-tls secret in the default namespace, we can now see we have a keystore.p12, truststore.p12 and ca.crt value in our secret. These can then be mounted to our Java workload.

```bash
k get secret wildcard-tls -o yaml |grep -e keystore -e truststore -e ca.crt
    ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURNakNDQWhxZ0F3....
    keystore.p12: MIIM4wIBAzCCDK8GCSqGSIb3DQEHAaCCDKAEggycMIIMmDCCB08GCSqGSIb3DQEHBqCCB....
    truststore.p12: MIIEVgIBAzCCBCIGCSqGSIb3DQEHAaCCBBMEggQPMIIECzCCBAcGCSqGSIb....
```

### Generate a Trust bundle

Create a bundle trust manager resource to generate a CA cert bundle that includes both common CAs as well as our custom CA certificate

```bash
cat << EOF > bundle.yaml
---
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: chainguard.dev
  namespace: cert-manager
spec:
  sources:
  # Include a bundle of publicly trusted certificates which can be
  # used to validate most TLS certificates on the internet
  - useDefaultCAs: true
  - secret:
      name: root-secret
      key: ca.crt
  target:
    configMap:
      key: "bundle.pem"
    additionalFormats:
      jks:
        key: "bundle.jks"
      pkcs12:
        key: "bundle.p12"
    namespaceSelector:
      matchLabels:
        create-certs: "true"
EOF

kubectl apply -f bundle.yaml

# Label namespace for bundle creation
kubectl label ns default create-certs=true

# Validate cert bundle
kubectl get cm chainguard.dev -n default -o yaml
.....
    -----BEGIN CERTIFICATE-----
    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
    -----END CERTIFICATE-----
....
```

## Example adding to Java App

Next let's build our Java sample app and mount our secrets in a Java Keystore

```bash
docker build -t localhost:5000/java-app:v1.0 .
# Push to our local registry
docker push localhost:5000/java-app:v1.0
```

Create a deployment manifest for our appp
```bash
cat << EOF > deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: java-app
  name: java-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: java-app
  strategy: {}
  template:
    metadata:
      labels:
        app: java-app
    spec:
      containers:
      - image: localhost:5000/java-app:v1.0
        name: java-app
        args:
        - "-Djavax.net.ssl.keyStorePassword=\$(KEYSTORE_PASS)"
        - "-Djavax.net.ssl.trustStorePassword=\$(KEYSTORE_PASS)"
        - "-Djavax.net.ssl.keyStore=/var/run/secrets/keystores/keystore.p12"
        - "-Djavax.net.ssl.keyStore=/var/run/secrets/keystores/truststore.p12"
        resources: {}
        volumeMounts:
        - mountPath: /var/run/secrets/keystores
          name: certs
        env:
        - name: KEYSTORE_PASS
          valueFrom:
            secretKeyRef:
              key: password
              name: keystore-pass
      volumes:
      - name: keystore-password
        secret:
          secretName: keystore-pass
      - name: certs
        secret:
          secretName: wildcard-tls
EOF

kubectl apply -f deployment.yaml -n default
```
