---
title: Homelab Redirection with Istio
date: 2024-02-10
description: 
tags: 
    - Istio
    - Homelab
    - K8s
    - Networking
categories:
    - Infrastructure
---

# Background

Recently wanted to try and set up a reverse proxy for some homelab services outside of a cluster, but use some cloud native services to do it. This is basically what I was thinking: https://technotim.live/posts/kube-traefik-cert-manager-le/.

I wanted to try and re-create that functionality with Istio instead of Traefik though, since it's something I should get more familiar with. 

# The goal

I'm on my desktop PC. I want to be able to point my PiHole DNS so that https://pve.local gets redirected to https://<proxmox-ip\>:8006. The DNS record will point to an Istio ingress running in a Kubeadm-generated cluster that will reverse-proxy the SSL connection to the actual Proxmox IP. 

# Installs
Some quick notes on installed services and methods before getting to the full configs in the next section. 

#### Kubeadm
Not much to say here. Basic install. 

#### Istio
Requires the istio-base and istiod installations. Didn't make any changes to default helm values. This also includes deploying an ingress gateway via helm.
* https://istio.io/latest/docs/setup/install/helm/

#### MetalLB	
In order to get an actual IP for the load balancer, I used MetalLB. Otherwise it will just stay pending. It's pretty straight forward to install with manifest, but I wanted to make it easier to update the values as necessary, though it actually wasn't required. 
* https://metallb.universe.tf/installation/#installation-with-helm

# Setup

Instead of testing on an HTTPS service (proxmox) first, I wanted to test on something with HTTP to rule out any SSL issues while I got the networking up. For that, I just used a router that the proxmox server is behind and that exposes HTTP. 

### Istio Gateway
This is required for the gateway to know to accept traffic. 
```
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: nginx-gateway
spec:
  # The selector matches the ingress gateway pod labels.
  # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
  selector:
    istio: ingress
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "nginx.local"
    - "pve.local"
```

### Issue #1: external url access
Sometime early on, I realized that because I was using Calico and set the pod-network-cidr in Kubeadm to be 192.168.0.0/16, that range conflicted with the routers DHCP address range, and when I had a pod attempt to reach my router page, the request wasn't NAT'd properly and failed. At that point, I remade the cluster with a pod range of 10.10.0.0/16. I did try and update it with steps from this post here (https://stackoverflow.com/questions/60176343/how-to-make-the-pod-cidr-range-larger-in-kubernetes-cluster-deployed-with-kubead), but ran into issues and since this is just a test, it wasn't worth fixing. 
![cidr.png][cidr]

After remaking with a new IP range, the pods could reach 192.168 services. 

This should have been more obvious to me since it does note it pretty explicitly here: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network

## MetalLB Config

Before routing the ingress back to an external service I wanted to make sure that I could get the ingress to function properly with a basic nginx service exposed via loadbalancer after setting up a Layer 2 advertisement in MetalLB and an IP pool. 

IPAddressPool and L2Advertisement objects:
```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallbpool
  namespace: metallb-system
spec:
  # Production services will go here. Public IPs are expensive, so we leased
  # just 4 of them.
  addresses:
  - 192.168.1.90-192.168.1.99
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advert
  namespace: metallb-system
spec:
  ipAddressPools:
  - metallbpool
```

Creating and exposing an nginx service
```
k run nginx --image=nginx
k expose pod/nginx --type=ClusterIP --port=80 --target-port=80 --name=nginx2
```

![service.png][service]

### Issue #2: Advertising IP
This took the longest to figure out, and came down to needing two nodes. At first, this was a single node cluster and I couldn't get MetalLB to respond to ARP requests. 

Confirmed that:
* ARP requests from other VMs would reach the node
* MetalLB speaker node was assigning IPs and listening on the right interfaces
* Proxmox wasn't set to filter MAC addresses in any way
* There weren't any errors in MetalLB or Istio logs after updating the log policy to be more verbose. 
* Everything relevant here: https://metallb.universe.tf/troubleshooting/

Eventually, this issue (https://github.com/metallb/metallb/issues/1154) had this statement:

> If you use `arping` - make sure to execute it on a node which will not arp for the address itself - The node that homes the announcing metallb-speaker will ignore the arp requests from `arping`

Since I had tried executing arping from other nodes and it didn't work, that seems to imply a requirement to have more than one node because a single node won't respond to ARPs for itself even from other nodes.

After adding a second node, everything worked fine and the node started responding and the logs look normal. 

![logs.png][speaker-logs]
![arp.png][arp]

## Istio Config

The solution that Traefik had to route to an external service seemed convenient, but Istio doesn't seem to have as straight forward of a means to do that for an IP address forward that can edit the port also. The (at least only one I found) to get this implemented is like this:

```igress gateway -> virtualservice -> service (headless) -> endpoint (with external IP) ```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: pve-vs
spec:
  hosts:
  - pve.local1
  gateways:
  - nginx-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: headless-svc 
---
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  # Same as the Service name
  name: headless-svc
  namespace: default
subsets:
- addresses:
  # think that hostname doesn't matter here since ip is used
  - hostname: pve-local
    ip: <test-ip>
    #ip: 192.168.1.20
  ports:
  - name: http
    # the port on external service
    port: 80
    protocol: TCP
```

Because we have default Istio settings, a pod is able to reach the service as well, but if it was set to restrict based on its registry (REGISTRY_ONLY), a service entry (https://istio.io/latest/docs/reference/config/networking/service-entry/) would be required. Definitely have more to learn on the function of service entries. In addition to that restriction, they should allow other services to refer to the service entry and you can change the backing service or hosts, though I couldn't get the examples to make sense with a little experimenting. 

### Issue #3: SSL

All of this is to an HTTP service, but the goal is to get SSL termination working as well. I didn't get that far, but that's next. I thought that an error I was originally getting was due to an SSL forwarding problem and added a destinationrule to disable the MTLS, but that didn't seem to make a difference for an HTTP service, so I removed it. 

## Fin
Just have to point the PiHole to the right IP and then I can get to the router page by visiting the url:
```
pat@home:~/Desktop$ curl http://pve.local1
<html><meta http-equiv=Refresh content=0;url=/...
```


# Next
* SSL. The whole point is redirect to services that aren't HTTP. Should be easy to set up LE certs for the termination at ingress, but unsure about the issues with connecting to the external SSL. 
* Put this into a repo on GH somewhere to build out and make into Helm or something. 
* Continued learning about: VirtualService. It seems like all of this should have been possible with just a VS, but I couldn't get that to work. 

# Links
In no particular order, and partially covered throughout above. 
https://istio.io/latest/docs/reference/config/networking/service-entry
https://istio.io/latest/docs/setup/additional-setup/gateway/
https://istio.io/latest/docs/ops/common-problems/network-issues/
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network
https://learncloudnative.com/blog/2023-02-10-servicentry-feature
https://alexandre-vazquez.com/istio-serviceentry/
https://github.com/metallb/metallb/issues/1154
