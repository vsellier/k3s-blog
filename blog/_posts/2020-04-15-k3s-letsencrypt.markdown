---
layout: post
title:  "HTTPS & Let's Encrypt"
date:   2020-02-08 12:00:00 +0100
tags: [kubernetes, k3s, traefik 1.7, let's encrypt, cert-manager, https, TLS v1.0, TLS v1.1, certificate]
---

## Introduction

In this post, we will see how use the [cert manager](https://cert-manager.io/) tool to automatically manage the ssl certificates via [Let's Encrypt](https://letsencrypt.org/)

K3S 1.17 comes with Traefik 1.7 as ingress controller. This version doesn't support Let's Encrypt certificate directly as explained in [the documentation](https://docs.traefik.io/v1.7/configuration/backends/kubernetes/#tls-certificates-management).

> Only TLS certificates provided by users can be stored in Kubernetes Secrets. Let's Encrypt certificates cannot be managed in Kubernets Secrets yet.

So the common way to support automatic generation of the ssl certificate is to use [cert manager](https://cert-manager.io/).

## Installation

[A regular installation via standard kubernetes component](https://cert-manager.io/docs/installation/kubernetes/#installing-with-regular-manifests) or [a simplified installation via helm are available](https://cert-manager.io/docs/installation/kubernetes/#installing-with-helm).
As helm is available by default with k3s, this is the installation method we will use.

```bash
# Declare the new resources type on the cluster
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.1/deploy/manifests/00-crds.yaml
# Create the namespace containing the cert-manager elements
kubectl create namespace cert-manager
# Install cert manager with helm
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.13.1
 ```

If everything worked as expected, there should be 3 pods started on the ``cert-manager`` namespace :

```bash
$ ./k3s kubectl get pods --namespace cert-manager
NAME                                       READY     STATUS    RESTARTS   AGE
cert-manager-7cb745cb4f-zxpc9              1/1       Running   0          1d
cert-manager-cainjector-778cc6bd68-bkt7n   1/1       Running   0          1d
cert-manager-webhook-69894d5869-2x89t      1/1       Running   0          1d
```

The role of these pods are explained in this [page](https://cert-manager.io/docs/concepts/)

## Ingress configuration

New ``cert-manager`` is installed, several other configuration are needed :

* One or more [certificate issuers](https://cert-manager.io/docs/configuration/)
* A certificate object defining the certificate properties and the filter(s) to use it
* Adding annotations on the ingress definition

### The issuers

2 issuers are configured, Let's encrypt staging for the tests and Lets's encrypt production.

```yaml
{% include cert-manager/issuers.yml %}
```

and

```bash
$ kubectl apply -f issuer.yml
# Validation
$ kubectl get issuers -o wide                                 [0:30:14]
NAME                  READY     STATUS                                                 AGE
letsencrypt-staging   True      The ACME account was registered with the ACME server   1d
letsencrypt           True      The ACME account was registered with the ACME server   1d
```

### The certificate

Now we have everything configured to ask Let's Encrypt to generate our certificates, we have to declare the certificate by itself. This certificate will be used later on the deployment.

```yaml
{% include cert-manager/certificate.yml %}
```

and

```bash
$ kubectl apply -f certificate.yml
# Validation
$ kubectl get certificates -o wide
NAME               READY     SECRET         ISSUER        STATUS                                          AGE
k3s-blog.wip.ovh   True      k3s-blog-crt   letsencrypt   Certificate is up to date and has not expired   7s
```

The important properties on this file are :

* ``secretName`` : this is the kubernetes secret where the certificat will be stored. This secret will be used in the ingress declaration
* ``issuerRef`` : This is how the issuers is configured, on this particular case it must be one of the issuers configured previously ``letsencrypt`` for production and ``letsencrypt-staging`` for the tests
* ``commonName`` : This is the [main dns name](This is the main dns name) the certificate will be used for. Several alternative names can be specified if you want the certificate to be valide for several domains. This can be acheived via the property [``dnsNames``](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1alpha2.CertificateSpec).

The certificate is generated as soon the configuration is pushed to the cluster.

```bash
$ kubectl get certificates
NAME                     READY     SECRET          AGE
k3s-blog.wip.ovh         True      k3s-blog-crt    2d 
```
```bash
$ kubectl describe certificates/k3s-blog.wip.ovh
Name:         k3s-blog.wip.ovh
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"cert-manager.io/v1alpha2","kind":"Certificate","metadata":{"annotations":{},"name":"k3s-blog.wip.ovh","namespace":"default"},"spec":{"co...
API Version:  cert-manager.io/v1alpha2
Kind:         Certificate
Metadata:
  Creation Timestamp:  2020-03-03T23:33:58Z
  Generation:          1
  Resource Version:    16062973
  Self Link:           /apis/cert-manager.io/v1alpha2/namespaces/default/certificates/k3s-blog.wip.ovh
  UID:                 a6aed88a-1e36-4d44-beee-f8e11548d95c
Spec:
  Common Name:  k3s-blog.wip.ovh
  Dns Names:
    k3s-blog.wip.ovh
  Issuer Ref:
    Name:       letsencrypt
  Secret Name:  k3s-blog-crt
Status:
  Conditions:
    Last Transition Time:  2020-03-03T23:33:58Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2020-03-08T15:24:43Z
Events:                    <none>
```


### Updating the ingress configuration

Now the certificate is generated and available for use, the ingress control can be updated to inform the ingress controler the site can be accessed via https.

```yaml
{% include cert-manager/ingress.yml %}
```

The [``tls``](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls) section is used for that.
The site is now available by http and https..

An additional property ``ingress.kubernetes.io/ssl-redirect: "true"`` is also added on the metadata section to force the redirection from http to https

```bash
$ curl -v -s http://k3s-blog.wip.ovh
...
> GET / HTTP/1.1
> Host: k3s-blog.wip.ovh
> User-Agent: curl/7.64.1
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Content-Type: text/html; charset=utf-8
< Location: https://k3s-blog.wip.ovh/
...
```

```bash
$ curl -v -s -o /dev/null https://k3s-blog.wip.ovh  
...
> GET / HTTP/2
> Host: k3s-blog.wip.ovh
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/2 200
...
```

And that's it, the blog is now only accessible in https. 
It works well but the defaut configuration is not optimized. This is the test of the ssl configuration via the [ssl labs](https://www.ssllabs.com/ssltest/analyze.html?d=k3s-blog.wip.ovh) tool :

![Default ssl configuration](/assets/cert-manager/ssl-test-default.png)

Old TLS v1.0 and 1.1 protocols are activated in the default configuration and should be deactivated. This configuration in traefik 1.7 is done in the [global toml configuration](https://docs.traefik.io/v1.7/configuration/entrypoints/#specify-minimum-tls-version). In k3s traefik is deployed by an helm chart which is in charge to generate the toml configuration. The chart is configured in the ``/var/lib/rancher/k3s/server/manifests/traefik.yaml`` :

```yaml
$ cat /var/lib/rancher/k3s/server/manifests/traefik.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: https://%{KUBERNETES_API}%/static/charts/traefik-1.81.0.tgz
  valuesContent: |-
    rbac:
      enabled: true
    ssl:
      enabled: true
    metrics:
      prometheus:
        enabled: true
    kubernetes:
      ingressEndpoint:
        useDefaultPublishedService: true
    image: "rancher/library-traefik"
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
```

In the [chart's documentation](https://github.com/helm/charts/tree/master/stable/traefik) the ``ssl.tlsMinVersion`` can be used to specify the minimal version of the TLS protocol to use.

The ssl part can be updated to introduce the new ``tlsMinVersion`` :

```yaml
    ssl:
      enabled: true
      tlsMinVersion: VersionTLS12
```

After saving the file, traefik is reconfigured and redeployed automatically.

A new test allows to validate the configuration is well appliled :

![Improved ssl configuration](/assets/cert-manager/ssl-test-old-tls-disabled.png)

The toml file used by traefik is stored in a configmap. It can be checked directly to verify the traefik configuration. After the configuration change, the ``minVersion`` is well configured on the tls entryPoint :

```bash
$ kubectl describe --namespace kube-system configmap/traefik
Name:         traefik
Namespace:    kube-system
Labels:       app=traefik
              chart=traefik-1.81.0
              heritage=Helm
              release=traefik
Annotations:  <none>

Data
====
traefik.toml:
----
# traefik.toml
logLevel = "info"
defaultEntryPoints = ["http","https"]
[entryPoints]
  [entryPoints.http]
  address = ":80"
  compress = true
  [entryPoints.https]
  address = ":443"
  compress = true
    [entryPoints.https.tls]
      minVersion = "VersionTLS12"
      [[entryPoints.https.tls.certificates]]
      CertFile = "/ssl/tls.crt"
      KeyFile = "/ssl/tls.key"
  [entryPoints.prometheus]
  address = ":9100"
[ping]
entryPoint = "http"
[kubernetes]
  [kubernetes.ingressEndpoint]
  publishedService = "kube-system/traefik"
[traefikLog]
  format = "json"
[metrics]
  [metrics.prometheus]
    entryPoint = "prometheus"

Events:  <none>
```

The deployment history of the helm chart can also be consulted with this command to check if the configuration is well redeployed :

```bash
 $ helm --namespace kube-system history traefik
REVISION	UPDATED                 	STATUS    	CHART         	APP VERSION	DESCRIPTION
1       	Sat Jan 25 18:54:48 2020	superseded	traefik-1.81.0	1.7.19     	Install complete
2       	Wed Apr 15 22:58:30 2020	deployed  	traefik-1.81.0	1.7.19     	Upgrade complete
```
