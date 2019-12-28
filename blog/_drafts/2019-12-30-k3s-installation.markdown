---
layout: post
title:  "K3S Installation"
date:   2019-11-23 12:21:30 +0100
tags: [kubernetes, raspberry, freebox delta]
---

## What is K3S

[K3S](https://k3s.io/) is a *Lightweight Kubernetes* edited by [Rancher](https://rancher.com). It's [open source](https://github.com/rancher/k3s) and "freely" availaible. It's easy to install, secured, and last but not the least, a certified kubernetes distribution. It means the api is compliant with any other kubernetes installation, managed or baremetal. It's a very good way to learn kubernetes in a constrained environment with limited resources like some raspbery pi and small vms.

## The lab

The testing environment will be composed by few arm powered servers :

- 1 raspberrypi 4 (RPI4), 4Go of RAM, booting on a 1To external USB SATA drive, Raspbian 10 (buster)
- 1 raspberrypi 3B+ (RPI3), 1Go of RAM, booting on a 1To external USB SATA drive, Raspbian 8 (jessie)
- 1 ARM powered VMs (VMB), 1 1CPU, 386Mo RAM, 40Go of disk space, Ubuntu 19.10. This VM is running on an internet box and will be the entry point of the cluster from the internet.

It's not compliant with all the prerequisites needed by k3s :

- Ubuntu 16 or 18 or Raspbian buster
- RAM: 512MB Minimum
- CPU: 1 Minimum
- SSD drives

But the goal is to learn and discover the behavior of the cluster at the limits.

This following organization will be used :

- RPI4: master
- RPI3: agent1
- VMB: agent2

## Installation

The [recommended installation](https://rancher.com/docs/k3s/latest/en/quick-start/) procedure is to use a shell script with an [evil curl\|bash](https://cmdline.nl/posts/evil-curl-bash/) :

```shell
# curl -sfL https://get.k3s.io | sh -
```

Personnaly, I prefer to convert this to little less evil ``wget/less/bash`` commands :

```shell
$ wget https://get.k3s.io -O /tmp/install.sh
$ less /tmp/install.sh
$ chmod u+x /tmp/install.sh && sudo /tmp/install.sh
```

A first look at the script shows it's pretty well organized and well commented.
Everything is handled from the k3s binary download, checksum verification, systemd configuration and log rotation.
There is no surprises or hidden configuration options not listed on the [dedicated page](https://rancher.com/docs/k3s/latest/en/installation/install-options/) (except the availability for developpers to install a specific version of k3s but it's out of the current scope).

So let's perform the installation on the master first.

### The master

**NOTE**: The ``K3S_NODE_NAME`` is used to force the node name instead of using the hostname.

```
$ sudo K3S_NODE_NAME=RPI4 /tmp/install.sh
[INFO]  Finding latest release
[INFO]  Using v1.0.1 as release
[INFO]  Downloading hash https://github.com/rancher/k3s/releases/download/v1.0.1/sha256sum-arm.txt
[INFO]  Downloading binary https://github.com/rancher/k3s/releases/download/v1.0.1/k3s-armhf
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service -> /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
```

That's it! The master is running correctly :

```
$ systemctl status k3s
* k3s.service - Lightweight Kubernetes
   Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2019-12-30 13:52:56 GMT; 22s ago
     Docs: https://k3s.io
  Process: 2112 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
  Process: 2113 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
 Main PID: 2114 (k3s-server)
    Tasks: 76
   Memory: 368.6M
   CGroup: /system.slice/k3s.service
           |-2114 /usr/local/bin/k3s server
           |-2152 containerd -c /var/lib/rancher/k3s/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/k3s/agent/containerd
           |-2468 /var/lib/rancher/k3s/data/182bf1607a98af006c64bf65c7e0aeaa6fef00309ac072b56edef511f34d2ac4/bin/containerd-shim-runc-v2 -namespace k8s.io -id d1856033e20a7d266ca2993d3eae07be49dda6452b241e8bbaabb01832ef29ad -address /run/k3s/containerd/containerd.sock
           |-2515 /var/lib/rancher/k3s/data/182bf1607a98af006c64bf65c7e0aeaa6fef00309ac072b56edef511f34d2ac4/bin/containerd-shim-runc-v2 -namespace k8s.io -id 078cc41da44cabfcbdac3d4d7a8c4b15d30b2e050aa6eff3341b2758e0bd5685 -address /run/k3s/containerd/containerd.sock
           |-2536 /var/lib/rancher/k3s/data/182bf1607a98af006c64bf65c7e0aeaa6fef00309ac072b56edef511f34d2ac4/bin/containerd-shim-runc-v2 -namespace k8s.io -id 175bbb8ce2e03a5a4361a3e2cb291cc27b80c3112578c9b49c8889401845fa54 -address /run/k3s/containerd/containerd.sock
           |-2545 /var/lib/rancher/k3s/data/182bf1607a98af006c64bf65c7e0aeaa6fef00309ac072b56edef511f34d2ac4/bin/containerd-shim-runc-v2 -namespace k8s.io -id 9a224ecfb30cad06167f845bad39920525ab92c90bb3d49547f6ea7f43818fc2 -address /run/k3s/containerd/containerd.sock
           |-2578 /pause
           |-2603 /pause
           |-2610 /pause
           `-2617 /pause
```

The kubernetes commands are available throught the k3s command acting just like a proxy.

```
$ sudo k3s kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
rpi4   Ready    master   33s   v1.16.3-k3s.2
```

During the installation a token is automatically generated. This token is used to authenticate the agents. It's located on the file ``/var/lib/rancher/k3s/server/token``. The token will be passed to the install script with the master url to properly configure the worker nodes.

```
$ sudo cat /var/lib/rancher/k3s/server/token
K105b0fc8...6b407::server:3245...c34f
```

### Deploying the worker nodes

```
$ sudo K3S_TOKEN=K105b0fc8...6b407::server:3245...c34f K3S_URL=https://<master ip>:6443 K3S_NODE_NAME=[RPI3|VMB] /tmp/install.sh
[INFO]  Finding latest release
[INFO]  Using v1.0.1 as release
[INFO]  Downloading hash https://github.com/rancher/k3s/releases/download/v1.0.1/sha256sum-arm.txt
[INFO]  Downloading binary https://github.com/rancher/k3s/releases/download/v1.0.1/k3s-armhf
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink from /etc/systemd/system/multi-user.target.wants/k3s-agent.service to /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent
```

The installation behavior is a litlle different than in the master. The service is names ``k3s-agent`` and the uninstall script ``k3s-agent-uninstall.sh``.

Wait few seconds to let k3s to download all it's components and the cluster is up : 
```
$ sudo k3s kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
rpi4   Ready    master   15m   v1.16.3-k3s.2
rpi3   Ready    <none>   25m   v1.16.3-k3s.2
vmb    Ready    <none>   5s    v1.16.3-k3s.2
```

For the moment, the cluster is up without any node disctinction. The services will be deployed according the resources available on the workers.
The node with the most resources available will be used primarily, the RPI4 node in this case.
