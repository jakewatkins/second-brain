# Phase 0: Second Brain Infrastructure

This directory contains all the infrastructure components needed to deploy the Second Brain system using Docker containers on macOS.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Slack       │    │    Traefik      │    │     Ollama      │
│   (External)    │    │ (Docker:443/80) │    │ (Local:11434)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
           │                     │                     ▲
           │                     ▼                     │
           │            ┌─────────────────┐            │
           └───────────►│      N8N        │◄───────────┘
                        │(Docker:HTTPS)   │
                        └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Notion      │
                       │   (External)    │
                       └─────────────────┘
```

## 📋 Prerequisites

- **macOS**: Sonoma 14+ or Sequoia 15+
- **Docker Desktop**: Latest version with Docker Compose
- **Ollama**: Installed locally on host machine
- **Hardware**: Minimum 8GB RAM (16GB recommended)
- **Storage**: 20GB+ free space
- **Accounts**: Slack workspace, Notion account

## 🚀 Quick Start

### 1. Configure Environment

Copy the environment template and fill in your credentials:

```bash
cp .env.template .env
# Edit .env with your actual tokens and IDs
```

Required credentials:
- Notion integration token (from https://www.notion.so/my-integrations)
- Notion database IDs (from your Second Brain databases)
- Slack bot token (from https://api.slack.com/apps)
- Slack webhook URL
- Slack channel ID for sb-inbox
- Hostname for HTTPS setup (default: fairladyz.local)

### 2. Setup Hostname Resolution

Add hostname entries to your hosts file:

```bash
sudo echo "127.0.0.1 fairladyz.local n8n.fairladyz.local traefik.fairladyz.local" >> /etc/hosts
```

### 3. Generate SSL Certificates

Generate self-signed certificates for HTTPS:

```bash
chmod +x generate-certs.sh
./generate-certs.sh
```

### 4. Start Infrastructure

Make scripts executable and start services:

```bash
chmod +x start.sh stop.sh backup.sh
./start.sh
```

This will:
- Create the Docker network
- Start Traefik reverse proxy
- Start N8N with HTTPS support
- Verify service health
- Display access URLs

### 5. Access Services

- **N8N Web Interface**: https://n8n.fairladyz.local (admin/changeme123)
- **Traefik Dashboard**: https://traefik.fairladyz.local
- **Local Ollama API**: http://localhost:11434

**Note**: Your browser will show security warnings for self-signed certificates. Click "Advanced" → "Proceed to site".

### 6. Verify Ollama Installation

Ensure Ollama is installed locally and has a model:

```bash
# Check Ollama status
ollama list

# Install a model if none exists (recommended)
ollama pull llama3.2:3b

# Test Ollama API
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello",
  "stream": false
}'
```

### 5. Configure N8N

1. Open http://localhost:5678
2. Create admin account
3. Install required nodes (Slack, Notion, HTTP Request)
4. Proceed to Phase 1 for workflow configuration

## 📂 Directory Structure

```
phase0-infrastructure/
├── docker-compose.yml          # Master compose file (N8N + Traefik)
├── .env.template               # Environment variables template
├── .env                        # Your actual credentials (git-ignored)
├── .gitignore                  # Excludes sensitive files
├── generate-certs.sh           # SSL certificate generation script
├── start.sh                    # Startup script
├── stop.sh                     # Shutdown script
├── backup.sh                   # Backup script
├── traefik-data/               # Traefik configuration data
├── certs/                      # SSL certificates
├── n8n-data/                   # N8N persistent data
└── n8n-logs/                   # N8N application logs
```

## 🛠️ Management Commands

### Start Services
```bash
./start.sh
```

### Stop Services
```bash
./stop.sh
```

### Create Backup
```bash
./backup.sh
```
Backups are stored in `~/second-brain-backups/`

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs n8n
docker-compose logs ollama

# Follow logs in real-time
docker-compose logs -f
```

### Check Service Status
```bash
docker-compose ps
```

### Restart Services
```bash
docker-compose restart
```

### Regenerate SSL Certificates
```bash
./generate-certs.sh
docker-compose restart traefik
```

## 🔍 Troubleshooting

### Services Won't Start

Check if Docker is running:
```bash
docker info
```

Check port availability:
```bash
lsof -i :443  # HTTPS
lsof -i :80   # HTTP
lsof -i :11434 # Ollama (local)
```

### Browser Security Warnings

Since we use self-signed certificates, browsers show security warnings:
- **Chrome/Edge**: Click "Advanced" → "Proceed to site"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"

### Hostname Resolution Issues

Ensure hostname is in `/etc/hosts`:
```bash
cat /etc/hosts | grep fairladyz.local
```

If missing, add it:
```bash
sudo echo "127.0.0.1 fairladyz.local n8n.fairladyz.local traefik.fairladyz.local" >> /etc/hosts
```

### Ollama Connection Issues

Check local Ollama service:
```bash
ollama list
curl http://localhost:11434/api/tags
```

Restart Ollama if needed:
```bash
brew services restart ollama
```

### N8N Access Issues

Verify service health:
```bash
curl -k https://n8n.fairladyz.local
```

Check service logs:
```bash
docker-compose logs n8n
docker-compose logs traefik
```

Reset N8N data (nuclear option):
```bash
./stop.sh
rm -rf ./n8n-data/*
./start.sh
```

### Network Issues

Recreate Docker network:
```bash
docker network rm second-brain-net
docker network create second-brain-net
docker-compose up -d
```

## 🔒 Security Notes

- `.env` file contains sensitive credentials - **never commit to git**
- Using self-signed certificates for local development
- N8N requires HTTPS for Slack OAuth integrations
- Default N8N credentials: admin/changeme123 - **change immediately**
- Certificates valid for 365 days - regenerate with `./generate-certs.sh`
- All databases should be private/shared only with integration
- Regular backups recommended
- Rotate API tokens periodically

## 📊 Resource Usage

Typical resource consumption:
- **Traefik**: 50-100MB RAM
- **N8N**: 200-500MB RAM
- **Ollama (local)**: 2-4GB RAM (depending on model)
- **Disk**: 1-2GB for N8N data, certificates, and logs

## 🔄 Updates

Update container images:
```bash
docker-compose pull
docker-compose up -d
```

## 📚 Next Steps

After completing infrastructure setup:

1. **Phase 1**: Configure N8N workflows
2. **Phase 2**: Set up Notion databases
3. **Phase 3**: Configure Slack integration
4. **Phase 4**: End-to-end testing

## 📝 Notes

- Services configured with automatic restart (`unless-stopped`)
- Data persists in `./data/` directories
- Logs available in `./logs/` directories
- Backups exclude Ollama models (too large)
- Network uses bridge driver with custom subnet (172.20.0.0/16)

## 🆘 Support

For detailed deployment instructions, see [Phase0-deployment.plan.md](../Phase0-deployment.plan.md)

---

**Infrastructure Status**: Ready for workflow configuration 🎉
