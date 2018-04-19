#!/bin/bash

# Uninstall old Docker distributions built into CentOS
sudo yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine \
    docker-ce

# Install Docker EE engine
export DOCKER_EE_URL=$(cat /vagrant/env/ee_url)
sudo -E sh -c 'echo "$DOCKER_EE_URL/centos" > /etc/yum/vars/dockerurl'
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo -E yum-config-manager --add-repo "${DOCKER_EE_URL}/centos/docker-ee.repo"
sudo yum -y install docker-ee
sudo usermod -aG docker vagrant
sudo systemctl start docker

# Configure DNS using dnsmasq on localhost
sudo yum install -y dnsmasq
sudo sh -c "echo 'interface=vboxnet1
listen-address=172.17.0.1' > /etc/dnsmasq.d/docker-bridge.conf"
sudo systemctl restart dnsmasq
