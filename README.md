Going to try to both put together a place I can write some stuff down, and experiment with a bit of a contrived example for K8s and other related DSO concepts. 

Tons of notes off-git while I hopefully make them presentable, but should cover a few learning points. 

Ideas:
* [x] A domain: patrickreber.com
* [x] Kubeadm created, EC2 hosted K8s cluster 
	* [ ] Post about it and why that choice
	* [ ] CF/UserData to spin up/down 
	* [ ] TF/Ansible to spin up/down
	* [ ] An alternative (waiting on homelab)
* [x] A way to get to it
	* [ ] Post about it and the comparisons
* [x] A framework
	* [ ] Configured so that it doesn't look like shit
 		* [ ] Poison 
 		* [ ] https://github.com/dillonzq/LoveIt?tab=readme-ov-file
		* [X] https://github.com/CaiJimmy/hugo-theme-stack-starter
	* [ ] post
* [X] GitOps automation - Commit to git, blog updates
	* [ ] Post
 	* [ ] GitOps v2: Jenkins in cluster running SCA/DCA?
* [ ] IB Images
* [ ] K8s additions:
	* [ ] Storage: rook/ceph (not necessary for the use case but need to learn it more. Different test case/repo?)
	* [ ] Service mesh (test istio ingress since nginx didn't work out w/ CF)
 	* [ ] netpols (and properly namespacing)
  	* [ ] GitOps -> Helm? 
