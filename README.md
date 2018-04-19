Vagrant Virtualbox setup for Docker EE 2.0 on CentOS 7.4
========================

## Overview

### Repository structure

This vagrant file is provided strictly for demonstration purposes to help setup a cluster environment that installs Docker EE, UCP, and DTR with embedded DNS. This can be used as a demo environment on your local machine, when internet access is not present. The organization of this repo is as follows:

- `env` - where environment variables are stored and read for bringing up EE platform
- `files` - configuration files for load balancers, etc
- `scripts` - scripts executed by VagrantFile
- `Makefile` - file used to create simple commands via `make` which invoke the Vagrant CLI
- `Vagrantfile` - file used to provisioning of infrastructure as invoked by Vagrant CLI

### Vagrant VMs provisioned

By default, after running `make start` the following will be provisioned and installed:
- UCP node - UCP will be accessible from `https:\\ucp.local` resolved through DNS (login: docker / dockeradmin ), provisioned with 2.5 GB RAM and 2 CPU
- DTR node - DTR will be accessible from `https:\\dtr.local` resolved through DNS, provisioned with 2 GB RAM and 2 CPU
- 2 worker nodes (`worker-node1` and `worker-node2`) - provisioned with 1GB RAM and 2 CPU each
- Gitlab CE node (Optional) - Gitlab will be accessible from `https:\\gitlab.local` resolved through DNS, provisioned with 2.5 GB RAM and 2 CPU
- Jenkins worker node (Optional) - worker node that runs Jenkins container, provisioned with 1GB RAM and 2 CPU each

### Static IPs set by default

This template will also setup the VMs with static ip addresses as follows (if IP addresses are already in use, change them inside of the Vagrantfile):
- `ucp` (UCP manager node): 172.28.128.31
- `ucp-node2` (UCP manager node2): 172.28.128.32 - Optional
- `ucp-node3` (UCP manager node3): 172.28.128.33 - Optional
- `dtr` (DTR replica): 172.28.128.34
- `worker-node1` (Worker node): 172.28.128.35
- `worker-node2` (Worker node): 172.28.128.36
- `gitlab` (Gitlab node): 172.28.128.37 - Optional
- `haproxy` (HA Proxy node): 172.28.128.30 - Optional, HAProxy Stats will be accessible from `https:\\haproxy.local:9000` (login: `admin` / `admin`)
- `jenkins` (Jenkins node): 172.28.128.38 - Optional

### DNS entries created for VMs

DNS entries for landrush:
- `dtr.local`: 172.28.128.34
- `ucp.local`: 172.28.128.31
- `wordpress.local`: 172.28.128.35
- `jenkins.local`: 172.28.128.35
- `nodeapp.local`: 172.28.128.35
- `visualizer.local`: 172.28.128.35
- `gitlab.local`: 172.28.128.31

## Getting Started

1. #### Download vagrant from Vagrant website
```
https://www.vagrantup.com/downloads.html
```

2. #### Install Virtual Box
```
https://www.virtualbox.org/wiki/Downloads
```

3. #### Create files in the `/env` folder to store environment variables with custom values for use by Vagrant
```
ee_url
ucp_username
```
For the `ee_url` file make sure the format of the ee_url is like the following
```
https://storebits.docker.com/ee/linux/sub-xxx-xxx-xxx-xxx-xxx
```

4. #### Provide Docker EE license in `/files` folder (will fail if not provided)
```
docker_subscription.lic
```

5. #### Install [vagrant-landrush](https://github.com/vagrant-landrush/landrush) plugin
```
vagrant plugin install landrush
vagrant plugin install vagrant-hostsupdater
```

6. #### Bring up nodes
If you are thinking of customizing the start up of the cluster (i.e. no DTR, HA UCP, etc) modify the `Makefile` to describe the `start`, `stop`, and `destroy` targets to manage certain nodes, if you only need a UCP manager node you can just edit the file to have the following entry for the `start` target.
```
start:
	@vagrant up haproxy ucp worker-node1 worker-node2
	...
destroy:
	@vagrant destroy -f ucp worker-node1 worker-node2
```

First lets set up a manager node to start our cluster, we'll use the `ucp` target instead to build a cluster with both swarm and kubernetes workers. If you want to just provision UCP and two swarm workers, use the `make start` target instead.
```
make ucp
```
Next, lets bring up kubernetes worker nodes by running the following commands to first set the orchestration mode to Kubernes and then provisioning and joining the kubernetes workers to the cluster.
```
# Switch orchestration to Kubernetes
make orch
# Provision and join workers
make workers
```
After setting up a swarm or kubernetes cluster with the previous commands, we'll go ahead and set up DTR. Before installing DTR, ensure that orchestration mode is set to Swarm. The following commands will first switch orchestration mode (back to Kubernetes from Swarm) and then provision a swarm worker node and install DTR.
```
# Switch orchestration mode to Swarm
make orch
# Provision node and install DTR
make dtr
```
7. ####  Install Gitlab CE and Jenkins (Optional)
	1. If you want to bring up a Gitlab CE node you can run the following command to bring up a VM that runs Gitlab CE without Docker
	```
	make gitlab
	```

	Then go login as `root`/`5iveL!fe` and create an Access Token by to going to Settings -> Access Tokens and export the token as an environment variables.
	```
	EXPORT GITLAB_TOKEN=<insert token>
	```

	2. Run the following command to configure Gitlab with a new project and webhooks using the GITLAB_TOKEN
	```
	make config-gitlab
	```

	3. After bringing up a Gitlab CE node you can then provision a Swarm node to run Jenkins on Docker EE.
	```
	make jenkins
	```

7. #### SSH into nodes
You can SSH directly into the nodes by specifying the names of each Vagrant VM
```
vagrant ssh ucp
```
8. #### Snapshot nodes
Take initial snapshot of nodes
```
make snap
```
Restore initial snapshot
```
make rollback
```
9. #### Stop nodes
```
make stop
```
10. #### Destroy nodes
```
make destroy
```
