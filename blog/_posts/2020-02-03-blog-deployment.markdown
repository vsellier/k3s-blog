---
layout: post
title:  "Deploying the static site"
date:   2020-02-03 12:00:00 +0100
tags: [kubernetes, jekyll, ingress, traefik]
---

## Architecture and the target

Deploying a static file without any other dependency except itself should not be too much complicated.
According to the documentation the container should be running in one or more [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) for the availability.

Manually starting the pods is not an option as I would like to simulate something highly available, upgradeable without downtime and scalable. It's also not a [kubernetes's best practice](https://kubernetes.io/docs/concepts/configuration/overview/#naked-pods-vs-replicasets-deployments-and-jobs).

So the Pods should be controlled by a [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) object as recommanded (instead of a [ReplicatSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)).

A [Service](https://kubernetes.io/docs/concepts/services-networking/service/) will be deployed to made the pods reacheable inside the whole cluster.

[K3S is coming with traefik](https://rancher.com/docs/k3s/latest/en/networking/#traefik-ingress-controller) as [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) controller. This part will be in charge of exposing the service outside the cluster.

The cluser topology is :

![The cluster topology](/assets/cluster-topology.png)

Few constraints to add more fun :

* The experiment is done on my home network, a port redirection will be configured on the internet router to expose the port ``80`` and ``443`` from the internet to the same ports on the ``VMB`` hosts
* The site will have to respond to the ``k3s-blog.wip.ovh`` address, initially only in http
* The resources of the VMB hosts are limited so the pods will have to be deployed on the ``RPI3`` and ``RPI4`` hosts

## Labeling the node

Kubernetes use a system of labels to manage [the pod's affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) to one or several nodes.
It can be used for affinity and anti-affinity. In this case an **affinity** to a label will be use to target the deployment on the raspberry nodes and an **anti-affinity** rule will be used to dispatch the pod on several nodes when it's possible.

First, let's add a label ``nodeType`` with the value ``compute`` on the raspberries.

1. List of the nodes

```bash
$ sudo ./k3s kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
rpi3   Ready    <none>   12d   v1.16.3-k3s.2
vmb    Ready    <none>   12d   v1.16.3-k3s.2
rpi4   Ready    master   12d   v1.16.3-k3s.2
```

2. Adding the label

```bash
$ sudo ./k3s kubectl label node rpi3 nodeType=compute
node/rpi3 labeled
$ sudo ./k3s kubectl label node rpi4 nodeType=compute
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

A [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) is used to start the pods and ensure they are correctly responding to the requests.

The minimal deployment configuration could be :

```yaml
{% include blog-deployment/deployment-minimal.yml %}```

The first important missing piece that must be added is the node affinity to ensure any pods will be started on the ``VMB`` node. It can be achieve with this syntax in the spec > template > spec section :

```yaml
      affinity:
        # Select the node to deploy on
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: nodeType
                operator: In
                values:
                  - compute
```

The ``requiredDuringSchedulingIgnoredDuringExecution`` keyword ensure the condition is respected when a new node is started.

The second condition, not mandatory[^1] but that can be add for this poc is the antiaffinity configuration to avoid to start the pods on the same nodes **if possible**.
It can be done with this other condition :

```yaml
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              podAffinityTerm:
                  topologyKey: kubernetes.io/hostname
                  labelSelector:
                    matchExpressions:
                    - key: app
                      operator: In
                      values:
                      - k3s-blog
```

The ``preferredDuringSchedulingIgnoredDuringExecution`` keyword allow the scheduler to create the pods even if the condition is not reached. If several rules are specified, the ``weight``s are summed and the node having the max score is selected to host the new pod.

[^1] Kubernetes will always try to position the pods in the best possible way and to avoid to duplicate pods on the same node.

Finally, the complete deployment looks like this :

```yaml
{% include blog-deployment/deployment-affinity.yml %}```

The deployment can be declared on the cluster with the ``apply`` command :

```bash
$ sudo ./k3s kubectl apply -f deployment-affinity.yml
deployment.apps/k3s-blog created
```

Let's looks at the statuses :

```bash
$ sudo ./k3s kubectl get deployments
NAME       READY     UP-TO-DATE   AVAILABLE   AGE
k3s-blog   0/2       2            0           1s
```

Something is alive but not yet up :

```bash
$ sudo ./k3s kubectl get pods -o wide
NAME                        READY     STATUS              RESTARTS   AGE       IP        NODE      NOMINATED NODE   READINESS GATES
k3s-blog-579bf6b596-5kv6b   0/1       ContainerCreating   0          3s        <none>    rpi4      <none>           <none>
k3s-blog-579bf6b596-4t6h4   0/1       ContainerCreating   0          3s        <none>    rpi3      <none>           <none>    
```

The pod creation is still in progress, as the image has to be downloaded from dockerhub, the pods can take few seconds to become online. After few seconds :

```bash
$ sudo ./k3s kubectl get deployments
NAME       READY     UP-TO-DATE   AVAILABLE   AGE
k3s-blog   2/2       2            2           8s   
```

```bash
$ sudo ./k3s kubectl get pods -o wide                       [23:22:38]
NAME                        READY     STATUS    RESTARTS   AGE       IP           NODE      NOMINATED NODE   READINESS GATES
k3s-blog-579bf6b596-5kv6b   1/1       Running   0          14s       10.42.0.21   rpi4      <none>           <none>
k3s-blog-579bf6b596-4t6h4   1/1       Running   0          14s       10.42.1.5    rpi3      <none>           <none>  
```

With the ``-o wide`` option, there is more information like the ip, the node hosting the pod returned by the command.

## The service

A service is composed of few properties, basically, the type, the selector to target the pods the service will communicate with, and the port(s) to redirect to :

```yaml
{% include blog-deployment/service.yml %}```

The type of service here is ``ClusterIP`` as the service will be exposed by the ingress controller. 
The other possible types of services and their use cases are explained on the [official documentation](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types).

```
$ sudo ./k3s kubectl apply -f service.yml
service/k3s-blog created
$ sudo ./k3s kubectl describe services/k3s-blog
Name:              k3s-blog
Namespace:         default
Labels:            <none>
Annotations:       kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"k3s-blog","namespace":"default"},"spec":{"ports":[{"port":80,"protocol":"TCP",...
Selector:          app=k3s-blog
Type:              ClusterIP
IP:                10.43.236.178
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.42.0.22:80,10.42.1.6:80
Session Affinity:  None
Events:            <none>
```

The service is now ready to be exposed via the ingress controller.

## The ingress controller

```yaml
{% include blog-deployment/ingress.yml %}```

An ingress is the same concept as an apache vhost. Several information have to be specified :
* The public hostname that will be used to reach the site
* The path filter, here, the site is deploy on the root so ``/`` is used
* The name of the service and the port to forward to matching the ``Name`` and the ``Port`` values declared on the previous step

Let's try if everything is working :
```
$ http --header http://k3s-blog.wip.ovh
HTTP/1.1 200 OK
...
```

The site is working. Any node of the cluster can be used as the entry point. The requests are redirected to traefik via internal proxies.
The internal communitcation mechanism will be described in another post.
