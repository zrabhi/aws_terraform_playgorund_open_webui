#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# using swap to prevent out of memory errors during docker build

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab


## Update package lists and install necessary packages
sudo apt-get update -y

sudo apt-get install -y curl ca-certificates gnupg nginx

## Install Docker 
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo systemctl enable docker
sudo systemctl start docker

# Install Ollama
sudo curl -fsSL https://ollama.com/install.sh | sh

sudo systemctl enable ollama
sudo systemctl start ollama

sleep 15

sudo ollama pull tinyllama

# Run Open-WebUI in a Docker container
sudo docker run -d \
  --name open-webui \
  -p 127.0.0.1:8080:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

 # Configure Nginx as a reverse proxy for Open-WebUI
sudo tee /etc/nginx/sites-available/openwebui > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/openwebui /etc/nginx/sites-enabled/

sudo systemctl restart nginx
sudo systemctl enable nginx