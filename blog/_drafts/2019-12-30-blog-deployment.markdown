---
layout: post
title:  "Deploying the static site"
date:   2020-01-05 12:00:00 +0100
tags: [kubernetes, jekyll, ingress, traefik]
---

## Architecture and the target

Deploying a static file without any other dependency except itself should not be too much complicated.
According to the documentation the container should be running in one or more [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) for the availability.
Manually starting the pods is not an option as I would like to simulate something highly available, upgradeable without downtime and scalable. It's also not a [kubernetes's best practice](https://kubernetes.io/docs/concepts/configuration/overview/#naked-pods-vs-replicasets-deployments-and-jobs).
So the Pods will be controlled by a [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) object as recommanded (compared to a [ReplicatSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)).

A [Service](https://kubernetes.io/docs/concepts/services-networking/service/) will be needed to made the pods reacheable inside the whole cluster.

[K3S is coming with traefik](https://rancher.com/docs/k3s/latest/en/networking/#traefik-ingress-controller) as [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) controller. This part will be in charge of exposing the service outside the cluster.

The cluser topology is :

![The cluster topology](/assets/cluster-topology.png)

Few constraints to add more fun :

* The experiment is done on my home network, a port redirection will be configured to expose the port ``80`` and ``443`` from the external to the same ports on the ``VMB`` hosts
* The site will have to respond to the ``k3s-blog.wip.ovh`` address, initially only in http
* The resources of the VMB hosts are limited so the pods will have to be deployed on the ``RPI3`` and ``RPI4`` hosts

## Labeling the node

Kubernetes use a system of abels to manage [the pod's affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) to one or several nodes.
It can be use for affinity and anti-affinity. In this case an **affinity** to a label will be use to target the deployment on the raspberry nodes and an **anti-affinity** rule will be used to dispatch the pod on several nodes.

First, let's add a label ``nodeType`` with the value ``compute`` on the raspaberries.

1. List of the nodes

```bash
sudo ./k3s kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
rpi3   Ready    <none>   12d   v1.16.3-k3s.2
vmb    Ready    <none>   12d   v1.16.3-k3s.2
rpi4   Ready    master   12d   v1.16.3-k3s.2
```

2. Adding the label

```bash
sudo ./k3s kubectl label node rpi3 nodeType=compute
node/rpi3 labeled
sudo ./k3s kubectl label node rpi4 nodeType=compute
node/rpi4 labeled
```

3. Testing the label

```bash
sudo ./k3s kubectl get nodes -l nodeType=compute
NAME   STATUS   ROLES    AGE   VERSION
rpi4   Ready    master   12d   v1.16.3-k3s.2
rpi3   Ready    <none>   12d   v1.16.3-k3s.2
```

👍 Only the 2 raspberry nodes are returned when requesting the nodes with the ``nodeType=compute`` label.

## The deployment

The minimal deployment configuration is :

```yaml
{% include blog-deployment/deployment-minimal.yml %}```



(Precision : By default the kubernetes scheduler will try to place the pods on the best way according the available resources, duplicate deployments, ... : [pod assignement](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/). The constraint to avoid 2 pods on the same server should noyt be explicity declared, but for the example, it will be recoded to 
