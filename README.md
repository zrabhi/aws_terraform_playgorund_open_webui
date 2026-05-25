# Open WebUI AWS Deployment (Terraform + Direnv + Ollama + NGINX)

## Overview

This project deploys a production-style Open WebUI setup on AWS EC2 using Terraform.

It includes:
- Open WebUI (Docker)
- Ollama (local LLM runtime)
- NGINX reverse proxy
- Terracurl health checks
- Direnv for environment management
- AWS infrastructure provisioning

---

## Requirements

Install the following tools locally:

- Terraform
- AWS CLI
- Docker (optional local testing)
- direnv
- 1Password CLI (`op`)
- SSH key stored in 1Password

---

## Architecture

User → NGINX (port 80) → Open WebUI (Docker 8080) → Ollama (11434)

---

## .envrc (Environment Setup with Direnv)

Create a file named `.envrc` in your project root.

This file automatically loads AWS credentials and Terraform variables when entering the directory.

### AWS Credentials (from 1Password)

The AWS credentials are securely retrieved from 1Password using the CLI.

- Access Key ID
- Secret Access Key
- Region

These are exported as environment variables for Terraform and AWS CLI usage.

---

### Terraform Variables

Terraform automatically reads variables prefixed with `TF_VAR_`.

This setup exports the AWS region so Terraform does not require manual input.

---

### Debug Output

The environment prints the AWS Access Key ID to confirm that credentials are loaded correctly.

---

### SSH Key Setup

The SSH public key is retrieved from 1Password and written to a temporary file:

- `/tmp/ssh_pub_key`

This file is used by Terraform to provision EC2 access.

---

### Terraform SSH Variable

The path to the SSH key is exported as a Terraform variable so it can be used dynamically during provisioning.

---

### Confirmation

When loaded successfully, the environment prints confirmation messages indicating:
- AWS credentials loaded
- SSH key created
- Environment ready for Terraform

---

## Enable Direnv

Before using the project:

```bash
eval "$(direnv hook bash)"
direnv allow
