#!/bin/bash
export UCP_VERSION=3.0.0

ip -o -4 addr list enp0s8 | awk '{print $4}' | cut -d/ -f1 > /vagrant/env/ucp-node1-ipaddr
export UCP_IPADDR=$(cat /vagrant/env/ucp-node1-ipaddr)
export UCP_USERNAME=$(cat /vagrant/env/ucp_username)
export UCP_FQDN=ucp.local

if [ ! -f /vagrant/files/ucp_password ]; then
  echo 'dockeradmin' > /vagrant/env/ucp_password
fi
export UCP_PASSWORD=$(cat /vagrant/env/ucp_password)

# Install UCP
if [[ $(cat /vagrant/files/docker_subscription.lic) ]]; then
  docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:${UCP_VERSION} install --force-minimums --host-address ${UCP_IPADDR} --admin-username ${UCP_USERNAME} --admin-password ${UCP_PASSWORD} --san ${UCP_FQDN} --license $(cat /vagrant/files/docker_subscription.lic)
else
  docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:${UCP_VERSION} install --force-minimums --host-address ${UCP_IPADDR} --admin-username ${UCP_USERNAME} --admin-password ${UCP_PASSWORD} --san ${UCP_FQDN}
fi

# Gather Swarm Tokens and UCP cluster id
sudo -E sh -c 'docker swarm join-token manager -q > /vagrant/env/swarm-join-token-mgr'
sudo -E sh -c 'sudo docker swarm join-token worker -q > /vagrant/env/swarm-join-token-worker'
docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:${UCP_VERSION} id | awk '{ print $1}' > /vagrant/env/ucp-id
export UCP_ID=$(cat /vagrant/env/ucp-id)

# Enable HRM
export AUTH_TOKEN="$(curl -sk -N -d "{\"username\":\"$UCP_USERNAME\",\"password\":\"$UCP_PASSWORD\"}" "https://${UCP_IPADDR}/auth/login" | jq -r .auth_token)"
curl -sk -X POST -H "Authorization: Bearer ${AUTH_TOKEN}" --header "Content-Type: application/json" --header "Accept: application/json" -d '{"HTTPPort":8080,"HTTPSPort":8443,"Arch":"x86_64"}' "https://${UCP_IPADDR}/api/interlock"
