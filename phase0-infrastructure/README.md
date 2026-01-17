# Phase 0: Second Brain Infrastructure

This directory contains all the infrastructure components needed to deploy the Second Brain system using Docker containers on macOS.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Slack       │    │      N8N        │    │     Ollama      │
│   (External)    │◄──►│  (Docker:5678)  │◄──►│ (Docker:11434)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
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

### 2. Start Infrastructure

Make scripts executable and start services:

```bash
chmod +x start.sh stop.sh backup.sh
./start.sh
```

This will:
- Create the Docker network
- Start Ollama and N8N containers
- Verify service health
- Display access URLs

### 3. Access Services

- **N8N Web Interface**: http://localhost:5678
- **Ollama API**: http://localhost:11434

### 4. Install AI Model

After services are running, install an AI model:

```bash
# Option 1: Llama 3.2 (smaller, faster - recommended)
docker exec -it second-brain-ollama ollama pull llama3.2:3b

# Option 2: Mistral (good balance)
docker exec -it second-brain-ollama ollama pull mistral:7b

# Option 3: Phi-3 (Microsoft, efficient)
docker exec -it second-brain-ollama ollama pull phi3:mini

# Verify installation
docker exec -it second-brain-ollama ollama list
```

### 5. Configure N8N

1. Open http://localhost:5678
2. Create admin account
3. Install required nodes (Slack, Notion, HTTP Request)
4. Proceed to Phase 1 for workflow configuration

## 📂 Directory Structure

```
phase0-infrastructure/
├── docker-compose.yml          # Master compose file
├── .env.template               # Environment variables template
├── .env                        # Your actual credentials (git-ignored)
├── .gitignore                  # Excludes sensitive files
├── start.sh                    # Startup script
├── stop.sh                     # Shutdown script
├── backup.sh                   # Backup script
├── config/
│   ├── n8n/
│   │   └── docker-compose.yml  # N8N-specific config
│   └── ollama/
│       └── docker-compose.yml  # Ollama-specific config
├── data/
│   ├── n8n/                    # N8N persistent data
│   └── ollama/                 # Ollama models and cache
└── logs/
    └── n8n/                    # N8N application logs
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

## 🔍 Troubleshooting

### Services Won't Start

Check if Docker is running:
```bash
docker info
```

Check port availability:
```bash
lsof -i :5678  # N8N
lsof -i :11434 # Ollama
```

### Ollama Model Issues

Check available space:
```bash
df -h
```

View Ollama logs:
```bash
docker logs second-brain-ollama
```

### N8N Access Issues

Verify service health:
```bash
curl http://localhost:5678/healthz
```

Reset N8N data (nuclear option):
```bash
./stop.sh
rm -rf ./data/n8n/*
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
- N8N and Ollama only accessible on localhost
- All databases should be private/shared only with integration
- Regular backups recommended
- Rotate API tokens periodically

## 📊 Resource Usage

Typical resource consumption:
- **Ollama**: 2-4GB RAM (depending on model)
- **N8N**: 200-500MB RAM
- **Disk**: 5-10GB for models + workflow data

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
