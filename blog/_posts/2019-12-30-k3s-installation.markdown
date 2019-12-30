---
layout: post
title:  "K3S Installation"
date:   2019-12-30 12:00:00 +0100
tags: [kubernetes, raspberry, freebox delta]
---

## What is K3S

[K3S](https://k3s.io/) is a *Lightweight Kubernetes* edited by [Rancher](https://rancher.com). It's [open source](https://github.com/rancher/k3s) and "freely" availaible. It's easy to install, secured, and last but not the least, a certified kubernetes distribution. It means the api is compliant with any other kubernetes installation, managed or baremetal. It's a very good way to learn kubernetes in a constrained environment with limited resources like some raspbery pi and small vms.

## The lab

The testing environment will be composed by few arm powered servers :

- 1 raspberrypi 4 (RPI4), 4Go of RAM, booting on a 1To external USB SATA drive, Raspbian 10 (buster)
- 1 raspberrypi 3B+ (RPI3), 1Go of RAM, booting on a 1To external USB SATA drive, Raspbian 8 (jessie)
- 1 ARM powered VMs (VMB), 1 1CPU, 384Mo RAM, 40Go of disk space, Ubuntu 19.10. This VM is running on an internet box and will be the entry point of the cluster from the internet.

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

## First issue

A difference of behaviour happens on the VMB node (the one with few memory) :
```
----system---- --total-cpu-usage-- -dsk/total- -net/total- ---paging-- ---system-- ---load-avg--- ------memory-usage----- ----swap---
     time     |usr sys idl wai stl| read  writ| recv  send|  in   out | int   csw | 1m   5m  15m | used  free  buff  cach| used  free
30-12 18:03:41|  4  31  50  14   0|  70M    0 | 439B 4468B|   0     0 |1950  3016 |3.22 4.36 2.72| 298M 5320k  680k 14.8M|   0     0
30-12 18:03:42|  7  49  36   8   0| 128M    0 |1196B 2398B|   0     0 |3362  4482 |3.22 4.36 2.72| 298M 3280k  136k 17.3M|   0     0
30-12 18:03:43|  4  36  55   6   0|  96M    0 | 151B  542B|   0     0 |2462  3190 |3.20 4.34 2.72| 298M 3304k  132k 17.1M|   0     0
30-12 18:03:44|  8  69  12  10   0| 261M    0 |3548B 4670B|   0     0 |6067  7344 |3.20 4.34 2.72| 298M 6120k  136k 14.5M|   0     0
30-12 18:03:45|  6  77   0  17   0| 145M    0 | 307B  768B|   0     0 |4357  4937 |3.20 4.34 2.72| 298M 4780k  140k 15.5M|   0     0
...
30-12 18:05:41|  7  92   0   1   0| 679M  240k|3965B 9459B|   0     0 |  11k   15k|4.04 4.16 2.85| 300M 4456k  144k 13.8M|   0     0  missed 5 ticks
30-12 18:05:46|  6  93   0   2   0| 394M   24k|2142B 4692B|   0     0 |7558    11k|4.04 4.16 2.85| 300M 2972k  204k 15.2M|   0     0  missed 5 ticks
30-12 18:05:49|  8  90   0   2   0| 398M    0 |2477B   10k|   0     0 |  14k   19k|4.12 4.18 2.86| 299M 4204k  488k 14.4M|   0     0  missed 2 ticks
30-12 18:06:00|  7  90   0   3   0|1528M 1504k|  15k   29k|   0     0 |  40k   52k|5.39 4.45 2.97| 300M 3768k  164k 15.0M|   0     0  missed 12 ticks
30-12 18:06:16|  6  92   0   1   0|2153M 3056k|7235B   18k|   0     0 |  45k   60k|6.05 4.66 3.07| 300M 2776k  216k 15.8M|   0     0  missed 16 ticks
```
The load is high and there is a lot of I/O. The server became unresponsive after few minutes.

The OOM killer was here :
```
Dec 30 18:08:17 front kernel: [606280.177800] oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),cpuset=system.slice,mems_allowed=0,global_oom,task_memcg=/kubepods/besteffort/podbe1e663f-f7a1-4b90-bdfd-bb30afdf7c37/53463dbb01e95cfa79e16677e4a67317688384cc5b6c54d416b48dce0f406b4c,task=entry,pid=19227,uid=0
Dec 30 18:08:17 front kernel: [606280.177828] Out of memory: Killed process 19227 (entry) total-vm:1656kB, anon-rss:120kB, file-rss:4kB, shmem-rss:0kB
...
Dec 30 18:11:08 front k3s[19377]: containerd: signal: killed
Dec 30 18:11:08 front systemd[1]: k3s-agent.service: Main process exited, code=exited, status=1/FAILURE
Dec 30 18:11:08 front systemd[1]: k3s-agent.service: Failed with result 'exit-code'.
Dec 30 18:11:13 front systemd[1]: k3s-agent.service: Service RestartSec=5s expired, scheduling restart.
Dec 30 18:11:13 front systemd[1]: k3s-agent.service: Scheduled restart job, restart counter is at 8.
Dec 30 18:11:13 front systemd[1]: Stopped Lightweight Kubernetes.
Dec 30 18:11:14 front systemd[1]: k3s-agent.service: Found left-over process 9987 (containerd-shim) in control group while starting unit. Ignoring.
```

First limit reached, 384Mo of ram is definitely not enough for ``k3s``.
Increasing the memory to 512Mo solved the issue, everything returned to normal.
