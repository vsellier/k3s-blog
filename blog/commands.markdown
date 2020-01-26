---
layout: page
title: Useful commands
permalink: /commands.html
---

| command | description |
|---------|-------------|
| k3s kubectl get all -A -o wide | list all the resources deployed on all the namespaces of the cluster |
|k3s kubectl logs -f --tail=100 --namespace kube-system $(k3s kubectl get --namespace kube-system pods -l app=traefik  -o name) | follow the traefik's pod logs|
|         |             |
