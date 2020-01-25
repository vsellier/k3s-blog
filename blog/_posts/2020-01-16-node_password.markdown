---
layout: post
title:  "K3S - Node password rejected"
date:   2020-01-16 12:00:00 +0100
tags: [kubernetes, k3s]
---

## Summary

This is a post relative to the learning of kubernetes with a small home lab with an arm64 VM, one raspberrypi 4 and one raspberrypi 3

This is the lab topology:

![The cluster topology](/assets/cluster-topology.png)

## Context

The ``VMB`` host was a VM not dedicated to the k3s cluster but also used to exposed some other web sites. The http/s ports were already in use so it wasn't possible to expose the kubernetes cluster services on this server as initially planned.
After changing the initial VMs ip (out of the scope of this post), the goal was to create a new VM with the same node name ``VMB`` and ip to keep the coherency with the previous posts. Bad and good idea as it seems it's not so straightforward.

## Cleanup

### On the cluster

The way to remove a node from a cluster is explain on this page : https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
Actually, there is still nothing deploy on the cluste so the node can be directly removed from the cluster with this commande :

```
# ./k3s kubectl delete node vmb
node "vmb" deleted
```
```
# ./k3s kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
rpi3   Ready    <none>   25d   v1.16.3-k3s.2
rpi4   Ready    master   25d   v1.16.3-k3s.2
```

### On the initial vm

The k3s agent uninstall is really easy as an unstall script is created during the installation :
```
vmb:~$ sudo /usr/local/bin/k3s-agent-uninstall.sh
+ id -u
+ [ 0 -eq 0 ]
+ /usr/local/bin/k3s-killall.sh
+ [ -s /etc/systemd/system/k3s-agent.service ]
+ basename /etc/systemd/system/k3s-agent.service
+ systemctl stop k3s-agent.service
+ [ -x /etc/init.d/k3s* ]
+ killtree 1214
+ kill -9 1214 1234 1286 1341
+ do_unmount /run/k3s
+ umount /run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io/3fb78e6fed087fb0070c25c13a796162d4fcdc5df876e433d52496fa90ae1964/rootfs /run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io/2ac4908d642e4c91c3228ff1a95314a16707c0fc686e14980701f9d51eaa8b6e/rootfs /run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io/002b99ba55fb96bec9277db9cdf83a603a04bb2d78ca34f0915ca5cd1081b59c/rootfs /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/002b99ba55fb96bec9277db9cdf83a603a04bb2d78ca34f0915ca5cd1081b59c/shm
+ do_unmount /var/lib/rancher/k3s
+ do_unmount /var/lib/kubelet/pods
+ umount /var/lib/kubelet/pods/9f8a697e-a62e-4fed-8fa0-dbe1809ac504/volumes/kubernetes.io~secret/default-token-2mlzh
+ do_unmount /run/netns/cni-
+ umount /run/netns/cni-7718d937-06a6-dd09-e8c4-778caf696ba8
+ read+  ignore iface ignore
grep master cni0
+ ip link show
+ ip link delete cni0
+ ip link delete flannel.1
+ rm -rf /var/lib/cni/
+ iptables-restore
+ grep -v CNI-
+ grep -v KUBE-
+ iptables-save
+ which systemctl
/usr/bin/systemctl
+ systemctl disable k3s-agent
Removed /etc/systemd/system/multi-user.target.wants/k3s-agent.service.
+ systemctl reset-failed k3s-agent
+ systemctl daemon-reload
+ which rc-update
+ rm -f /etc/systemd/system/k3s-agent.service
+ rm -f /etc/systemd/system/k3s-agent.service.env
+ trap remove_uninstall EXIT
+ [ -L /usr/local/bin/kubectl ]
+ rm -f /usr/local/bin/kubectl
+ [ -L /usr/local/bin/crictl ]
+ rm -f /usr/local/bin/crictl
+ [ -L /usr/local/bin/ctr ]
+ rm -f /usr/local/bin/ctr
+ rm -rf /etc/rancher/k3s
+ rm -rf /var/lib/rancher/k3s
+ rm -rf /var/lib/kubelet
+ rm -f /usr/local/bin/k3s
+ rm -f /usr/local/bin/k3s-killall.sh
+ remove_uninstall
+ rm -f /usr/local/bin/k3s-agent-uninstall.sh
```

##  Kube reinstalation

The installation on the new vm was done as exlained on this [previous post]({% post_url 2019-12-30-k3s-installation %}).

```bash
$ sudo K3S_TOKEN=K105b0f...66b407::server:32459a...a9c34f K3S_URL=https://192.168.30.21:6443 K3S_NODE_NAME=VMB /tmp/install.sh
[INFO]  Finding latest release
[INFO]  Using v1.17.0+k3s.1 as release
[INFO]  Downloading hash https://github.com/rancher/k3s/releases/download/v1.17.0+k3s.1/sha256sum-arm64.txt
[INFO]  Skipping binary downloaded, installed k3s matches hash
[INFO]  Skipping /usr/local/bin/kubectl symlink to k3s, already exists
[INFO]  Skipping /usr/local/bin/crictl symlink to k3s, already exists
[INFO]  Skipping /usr/local/bin/ctr symlink to k3s, already exists
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  No change detected so skipping service start
```

Unfortunately, after the install, the new node never came back to the ready state :

```log
root@raspberrypi:/var/lib/rancher/k3s/server/cred# k get nodes
NAME   STATUS                     ROLES    AGE     VERSION
rpi3   Ready,SchedulingDisabled   <none>   17d     v1.16.3-k3s.2
vmb    NotReady                   <none>   2m20s   v1.17.0+k3s.1
rpi4   Ready                      master   17d     v1.16.3-k3s.2
```

Let's look at the the agent logs to see what is going on : 

```
Jan 16 08:04:10 k3s-agent k3s[1561]: time="2020-01-16T08:04:10.073863274Z" level=info msg="Starting k3s agent v1.17.0+k3s.1 (0f644650)"
Jan 16 08:04:10 k3s-agent k3s[1561]: time="2020-01-16T08:04:10.082107663Z" level=info msg="module overlay was already loaded"
Jan 16 08:04:10 k3s-agent k3s[1561]: time="2020-01-16T08:04:10.413153041Z" level=info msg="module br_netfilter was already loaded"
Jan 16 08:04:10 k3s-agent k3s[1561]: time="2020-01-16T08:04:10.419236136Z" level=info msg="Running load balancer 127.0.0.1:36535 -> [19
2.168.30.21:6443]"
Jan 16 08:04:11 k3s-agent k3s[1561]: time="2020-01-16T08:04:11.984848590Z" level=error msg="Node password rejected, duplicate hostname or contents of '/etc/rancher/node/password' may not match server node-passwd entry, try enabling a unique node name with the --with-node-id flag"
```

Weird as the previous node was deleted before launching the installation.

There are some issues on the net talking about the problem :
[Removing node doesn't remove node password #802](https://github.com/rancher/k3s/issues/802)

The solution seems to be in this comment : [...kubectl should remove hostname:password from /var/lib/rancher/k3s/server/cred/node-passwd...](https://github.com/rancher/k3s/issues/802#issuecomment-531934837).

Let check that on ``RPI4`` the server :

```bash
rpi4:~$ sudo cat /var/lib/rancher/k3s/server/cred/node-passwd
661c99c09f347a8399990d0486b84fcf,vmb,vmb,
e21..........................8ba,rpi3,rpi3,
1d9..........................18c,rpi4,rpi4,
```

After removing the first line and restarting the agent, the authentication is correctly done without any other action on the master.

```bash
vmb:~$ sudo journalctl -f -u k3s-agent
Jan 16 21:21:34 k3s-agent k3s[2654]: time="2020-01-16T21:21:34.939369521Z" level=info msg="Starting k3s agent v1.17.0+k3s.1 (0f644650)"
Jan 16 21:21:34 k3s-agent k3s[2654]: time="2020-01-16T21:21:34.941691137Z" level=info msg="module overlay was already loaded"
Jan 16 21:21:34 k3s-agent k3s[2654]: time="2020-01-16T21:21:34.941775538Z" level=info msg="module nf_conntrack was already loaded"
Jan 16 21:21:34 k3s-agent k3s[2654]: time="2020-01-16T21:21:34.941810658Z" level=info msg="module br_netfilter was already loaded"
Jan 16 21:21:34 k3s-agent k3s[2654]: time="2020-01-16T21:21:34.950238317Z" level=info msg="Running load balancer 127.0.0.1:37663 -> [192.168.30.21:6443]"
Jan 16 21:21:35 k3s-agent k3s[2654]: time="2020-01-16T21:21:35.970418768Z" level=info msg="Logging containerd to /var/lib/rancher/k3s/agent/containerd/containerd.log"
Jan 16 21:21:35 k3s-agent k3s[2654]: time="2020-01-16T21:21:35.973744271Z" level=info msg="Running containerd -c /var/lib/rancher/k3s/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/k3s/agent/containerd"
Jan 16 21:21:39 k3s-agent k3s[2654]: time="2020-01-16T21:21:39.186379803Z" level=info msg="Connecting to proxy" url="wss://192.168.30.21:6443/v1-k3s/connect"
Jan 16 21:21:39 k3s-agent k3s[2654]: time="2020-01-16T21:21:39.290284249Z" level=info msg="Running kube-proxy --cluster-cidr=10.42.0.0/16 --healthz-bind-address=127.0.0.1 --hostname-override=vmb --kubeconfig=/var/lib/rancher/k3s/agent/kubeproxy.kubeconfig --proxy-mode=iptables"
```

Unfortunately, the node still didn't return to the ready state. Let's see what is on the logs this time :

```logs
Jan 16 21:24:08 k3s-agent k3s[3388]: E0116 21:24:08.077935    3388 csi_plugin.go:271] Failed to initialize CSINodeInfo: error updating CSINode annotation: timed out waiting for the condition; caused by: the server could not find the requested resource
```

The problem seems to be common when the versions of a node is not in sync with the master version.

A new k3s version was issued between the first cluster installation and the vms reinstallation. The new agent is in version ``v1.17.0+k3s.1`` as the other nodes are in version ``v1.16.3-k3s.2``.

It's possible to force the installer to install a specific version during the installation with the parameter ``INSTALL_K3S_VERSION`` but unfortunately, rancher has changed the version number format in the interval and the installer can't find the previous 1.16 versions :

![Version changes](/assets/k3s-versions.png)

```bash
$ sudo K3S_TOKEN=K105b0f...66b407::server:32459a...a9c34f K3S_URL=https://192.168.30.21:6443 K3S_NODE_NAME=VMB INSTALL_K3S_VERSION=v1.16.3-k3s.2 /tmp/install.sh
[INFO]  Using v1.16.3-k3s.2 as release
[INFO]  Downloading hash https://github.com/rancher/k3s/releases/download/v1.16.3-k3s.2/sha256sum-arm64.txt
$ echo $?
22
```
```bach
$ curl https://github.com/rancher/k3s/releases/download/v1.16.3-k3s.2/sha256sum-arm64.txt
Not Found
```

It seems a first cluster upgrade is on the way ...
