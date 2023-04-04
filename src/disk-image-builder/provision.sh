#!/usr/bin/env bash

set -ex

if [ $(id -u) -ne 0 ]; then
  exec sudo $0
fi
rm -rf /var/lib/apt/lists/*
apt-get -y update
apt-get -y upgrade
apt-get -y install ca-certificates \
  curl \
  gnupg \
  lsb-release \
  tzdata
ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker pull docker.io/caprover/caprover-edge:latest &
docker pull caprover/netdata &
docker pull caprover/certbot-sleeping &
docker pull caprover-placeholder-app &
wait
touch /etc/h2.env
# FIXME: Use source image filter?
# https://developer.hashicorp.com/packer/plugins/builders/openstack#source_image_filter
cat <<EOF >/etc/systemd/system/caprover.service
[Unit]
After=network.target
After=cloud-final.service
[Service]
EnvironmentFile=/etc/h2.env
ExecStart=/bin/sh -c "/usr/bin/docker run -e MAIN_NODE_IP_ADDRESS=\${MAIN_NODE_IP_ADDRESS} -e BY_PASS_PROXY_CHECK='TRUE' -p 80:80 -p 443:443 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain docker.io/caprover/caprover-edge:latest"
[Install]
WantedBy=default.target
WantedBy=cloud-init.target
EOF

chmod 664 /etc/systemd/system/caprover.service
systemctl daemon-reload
systemctl enable docker.service
systemctl enable containerd.service
systemctl enable caprover.service
