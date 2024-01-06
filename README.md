Going to try to both put together a place I can write some stuff down, and experiment with a bit of a contrived example for K8s and other related DSO concepts. 

Tons of notes off-git while I hopefully make them presentable, but should cover a few learning points. 


Ideas for infrastructure + content:
* [x] A domain: patrickreber.com
* [x] Kubeadm created, EC2 hosted K8s cluster 
	* [ ] Post about it and why that choice
	* [ ] An alternative (waiting on homelab)
* [x] A way to get to it
	* [ ] Post about it and the comparisons (why tunnel vs r53 vs NLB)
* [x] A framework
	* [ ] Configured so that it doesn't look like shit
 		* [ ] Poison 
 		* [ ] https://github.com/dillonzq/LoveIt?tab=readme-ov-file
		* [X] https://github.com/CaiJimmy/hugo-theme-stack-starter
	* [ ] post
* [X] GitOps automation - Commit to git, blog updates
	* [ ] Better scope for what gets triggered
	* [ ] Post
 	* [ ] GitOps v2: Jenkins in cluster running SCA/DCA?
* [ ] K8s additions:
	* [ ] SOPS/Sealed Secrets for LE-Certs and Tunnel-Creds 
	* [ ] Storage: rook/ceph (not necessary for the use case but need to learn it more. Different test case/repo?)
	* [ ] Service mesh (test istio ingress since nginx didn't work out w/ CF)
	* [ ] netpols (and properly namespacing)
	* [ ] GitOps -> Helm? 
	* [ ] Going to need active communicating workloads at some point to test more
* [ ] Deployment via CF ([Here eventually](https://github.com/reberp/AWS-automations/tree/main/CloudFormation))
* [ ] Deployment via Ansible/TF ([Here eventually](https://github.com/reberp/AWS-automations/))
