# Open WebUI on AWS (Terraform + Docker + Ollama + NGINX)

Deploy a self-hosted AI stack on AWS EC2 in a single `terraform apply`. The setup provisions infrastructure, installs Docker, runs Open WebUI and Ollama, configures NGINX as a reverse proxy, and waits for the service to become healthy before completing.

```
User → NGINX :80 → Open WebUI (Docker :8080) → Ollama :11434
```

---

## Stack

| Component | Role |
|-----------|------|
| **Terraform** | Infrastructure provisioning |
| **Docker** | Runs Open WebUI in a container |
| **Ollama** | LLM backend (host process) |
| **Open WebUI** | Chat interface |
| **NGINX** | Reverse proxy (port 80 → 8080) |
| **Direnv** | Per-project environment automation |
| **Terracurl** | Health-check polling at deploy time |

---

## Prerequisites

- Terraform
- AWS CLI
- Direnv
- 1Password CLI (`op`)

AWS credentials and your SSH public key must be stored in 1Password — they are pulled at runtime, never hardcoded.

---

## Environment Setup (Direnv + 1Password)

Direnv automatically loads environment variables when you enter the project directory and unloads them when you leave. AWS credentials and Terraform variables are sourced from 1Password via the `op` CLI.

### 1. Install direnv

```bash
sudo apt-get update && sudo apt-get install -y direnv
```

### 2. Hook direnv into your shell

**Bash:**
```bash
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc && source ~/.bashrc
```

**Zsh:**
```bash
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc && source ~/.zshrc
```

### 3. Create `.envrc`

```bash
export AWS_REGION=eu-west-3

export AWS_ACCESS_KEY_ID=$(op item get "Aws" --fields "Access key ID")
export AWS_SECRET_ACCESS_KEY=$(op item get "Aws" --fields "Secret access key")

export TF_VAR_AWS_REGION=$AWS_REGION

echo "$(op item get "Github" --fields "SSH pub key")" > /tmp/ssh_pub_key
export TF_VAR_SSH_PUB_KEY_PATH="/tmp/ssh_pub_key"
```

### 4. Allow the file

```bash
direnv allow
```

From this point on, entering the directory automatically configures your environment. Leaving it cleans everything up.

---

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

To tear down:

```bash
terraform destroy
```

---

## SSH Access

```bash
ssh ubuntu@$(terraform output --raw public_ip)
```

---

## What Terraform Provisions

- Ubuntu EC2 instance (`t3.micro`)
- Security group: port 80 open publicly, SSH restricted to your IP
- EC2 key pair (from 1Password)
- Root EBS volume
- `user_data` bootstrap script that:
  - Installs Docker
  - Pulls and runs Open WebUI on port 8080
  - Installs Ollama on the host
  - Downloads TinyLlama (lightweight, fits on t3.micro)
  - Configures NGINX to proxy port 80 → 8080
- Terracurl resource that polls `/api/health` until HTTP 200 before marking the apply complete

---

## Accessing the App

Once deployed:

```
http://<EC2_PUBLIC_IP>
```

---

## Debugging

```bash
# Check running containers
docker ps

# View Open WebUI logs
docker logs open-webui

# Inspect Docker service
journalctl -u docker
```

---

## Security Notes

- Only port 80 is publicly exposed. Ports 8080 and 11434 are internal only.
- SSH is restricted to your IP in the security group.
- Credentials are never stored in code — always retrieved from 1Password at runtime.
- Use strong, generated passwords for any application accounts. Avoid defaults like `admin` or `123456`.