# Phase 0: Infrastructure Deployment Plan

## Overview
This document provides step-by-step instructions for deploying all infrastructure components for the Second Brain system on macOS using Docker containers.

## Prerequisites

### System Requirements
- **macOS**: Latest version (Sonoma 14+ or Sequoia 15+)
- **Docker Desktop**: Latest version with Docker Compose
- **Hardware**: Minimum 8GB RAM (16GB recommended for Ollama)
- **Storage**: 20GB+ free space for Docker images and volumes

### Required Accounts
- **Slack**: Workspace admin access (or ability to create workspace)
- **Notion**: Personal or team account with API access
- **Docker Hub**: Account for image pulls (optional, but recommended)

## Infrastructure Components

### Component Overview
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

## Step 1: Docker Environment Setup

### 1.1 Install Docker Desktop
```bash
# Download and install Docker Desktop for Mac from:
# https://www.docker.com/products/docker-desktop/

# Verify installation
docker --version
docker-compose --version
```

### 1.2 Create Project Directory Structure
```bash
# Create project directory
mkdir -p ~/second-brain-infrastructure
cd ~/second-brain-infrastructure

# Create subdirectories
mkdir -p {n8n,ollama,config,data,logs}
mkdir -p data/{n8n,ollama}
mkdir -p config/{n8n,ollama}
```

### 1.3 Create Docker Network
```bash
# Create dedicated network for second-brain components
docker network create second-brain-net
```

## Step 2: Ollama Deployment

### 2.1 Create Ollama Configuration

**File: `~/second-brain-infrastructure/config/ollama/docker-compose.yml`**
```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: second-brain-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./data/ollama:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
    networks:
      - second-brain-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/version"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  second-brain-net:
    external: true
```

### 2.2 Deploy Ollama
```bash
cd ~/second-brain-infrastructure/config/ollama
docker-compose up -d

# Verify deployment
docker ps | grep ollama
docker logs second-brain-ollama

# Test API endpoint
curl http://localhost:11434/api/version
```

### 2.3 Install and Configure AI Model
```bash
# Pull a suitable model for classification (choose one)
# Option 1: Llama 3.2 (smaller, faster)
docker exec -it second-brain-ollama ollama pull llama3.2:3b

# Option 2: Mistral (good balance)
docker exec -it second-brain-ollama ollama pull mistral:7b

# Option 3: Phi-3 (Microsoft, efficient)
docker exec -it second-brain-ollama ollama pull phi3:mini

# Verify model installation
docker exec -it second-brain-ollama ollama list

# Test model response
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Hello world",
  "stream": false
}'
```

## Step 3: N8N Deployment

### 3.1 Create N8N Configuration

**File: `~/second-brain-infrastructure/config/n8n/docker-compose.yml`**
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: second-brain-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=America/Los_Angeles
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console
      - N8N_METRICS=true
      - N8N_DIAGNOSTICS_ENABLED=false
      - DB_TYPE=sqlite
      - DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
    volumes:
      - ./data/n8n:/home/node/.n8n
      - ./logs/n8n:/home/node/.n8n/logs
    networks:
      - second-brain-net
    depends_on:
      - ollama
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  second-brain-net:
    external: true
```

### 3.2 Deploy N8N
```bash
cd ~/second-brain-infrastructure/config/n8n
docker-compose up -d

# Verify deployment
docker ps | grep n8n
docker logs second-brain-n8n

# Test N8N web interface
open http://localhost:5678
```

### 3.3 Initial N8N Setup
1. **Open N8N Interface**: Navigate to `http://localhost:5678`
2. **Create Admin Account**:
   - Email: Your preferred email
   - Password: Strong password (save in password manager)
3. **Skip Usage Survey** (optional)
4. **Install Required Nodes**:
   - Slack (should be pre-installed)
   - Notion (should be pre-installed)
   - HTTP Request (for Ollama integration)

## Step 4: Container Orchestration

### 4.1 Create Master Docker Compose

**File: `~/second-brain-infrastructure/docker-compose.yml`**
```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: second-brain-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./data/ollama:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
    networks:
      - second-brain-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/version"]
      interval: 30s
      timeout: 10s
      retries: 3

  n8n:
    image: n8nio/n8n:latest
    container_name: second-brain-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=America/Los_Angeles
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console
      - N8N_METRICS=true
      - N8N_DIAGNOSTICS_ENABLED=false
      - DB_TYPE=sqlite
      - DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
    volumes:
      - ./data/n8n:/home/node/.n8n
      - ./logs/n8n:/home/node/.n8n/logs
    networks:
      - second-brain-net
    depends_on:
      - ollama
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  second-brain-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 4.2 Deploy Complete Stack
```bash
cd ~/second-brain-infrastructure

# Deploy entire stack
docker-compose up -d

# Verify all services
docker-compose ps
docker-compose logs

# Check service health
docker-compose exec ollama curl http://localhost:11434/api/version
curl http://localhost:5678/healthz
```

## Step 5: Slack Configuration

### 5.1 Create Slack Workspace (if needed)
1. **Go to** `https://slack.com/create`
2. **Create new workspace**:
   - Workspace name: `Second Brain` (or preferred name)
   - Workspace URL: `second-brain-[yourname]` 
3. **Skip team member invites** (personal workspace)
4. **Complete workspace setup**

### 5.2 Create SB-Inbox Channel
1. **Open Slack workspace**
2. **Create new channel**:
   - Name: `sb-inbox`
   - Description: `Second Brain capture point - one thought per message`
   - Make it **Private**
3. **Pin a message** explaining usage:
   ```
   📝 Second Brain Inbox
   
   Drop thoughts here - one per message. No organizing needed!
   
   Categories: people, projects, ideas, admin
   The AI will sort everything automatically.
   ```

### 5.3 Create Slack App for N8N Integration
1. **Go to** `https://api.slack.com/apps`
2. **Create New App** → **From scratch**
3. **App Settings**:
   - App Name: `Second Brain N8N`
   - Workspace: Select your Second Brain workspace
4. **OAuth & Permissions**:
   - Add **Bot Token Scopes**:
     - `channels:read` - View basic info about public/private channels
     - `channels:history` - View messages in public/private channels
     - `chat:write` - Send messages as app
     - `im:write` - Send DMs as app
     - `files:read` - View files shared in channels/conversations
5. **Install App to Workspace**
6. **Copy Bot User OAuth Token** (starts with `xoxb-`)
7. **Add bot to sb-inbox channel**:
   - Go to #sb-inbox
   - Type `/invite @Second Brain N8N`

### 5.4 Configure Slack Webhooks (for replies)
1. **In Slack App settings** → **Incoming Webhooks**
2. **Activate Incoming Webhooks** → On
3. **Add New Webhook to Workspace**
4. **Select #sb-inbox channel**
5. **Copy Webhook URL**

## Step 6: Notion Database Setup

### 6.1 Create Notion Integration
1. **Go to** `https://www.notion.so/my-integrations`
2. **Create new integration**:
   - Name: `Second Brain N8N`
   - Logo: Upload or skip
   - Associated workspace: Select your workspace
3. **Copy Internal Integration Token** (starts with `secret_`)

### 6.2 Create Second Brain Workspace Page
1. **In Notion**, create new page: `Second Brain`
2. **Add description**:
   ```
   🧠 Second Brain Knowledge Management System
   
   Automated capture and organization of thoughts, ideas, and tasks.
   Last updated: [Current Date]
   ```

### 6.3 Create Database 1: People
1. **In Second Brain page** → **Add a database** → **Table**
2. **Database name**: `People`
3. **Configure properties**:
   
   | Property Name | Type | Description |
   |---------------|------|-------------|
   | Name | Title | Person's name (auto-created) |
   | Context | Text | How you know them, relationship |
   | Follow-ups | Text | Things to remember for next time |
   | Last Touched | Date | When entry was last updated |
   | Tags | Multi-select | Categories (work, personal, etc.) |

4. **Share with integration**:
   - Click **Share** → **Invite** → Select `Second Brain N8N` → **Invite**

### 6.4 Create Database 2: Projects
1. **Add new database**: `Projects`
2. **Configure properties**:
   
   | Property Name | Type | Description | Options |
   |---------------|------|-------------|---------|
   | Name | Title | Project name | |
   | Status | Select | Current status | Active, Waiting, Blocked, Someday, Done |
   | Next Action | Text | Specific executable step | |
   | Notes | Text | Additional project details | |
   | Tags | Multi-select | Categories | |
   | Created | Date | When project was added | |

3. **Share with integration**

### 6.5 Create Database 3: Ideas
1. **Add new database**: `Ideas`
2. **Configure properties**:
   
   | Property Name | Type | Description |
   |---------------|------|-------------|
   | Name | Title | Idea title |
   | One-liner | Text | Core insight summary |
   | Notes | Text | Elaboration space |
   | Tags | Multi-select | Categories |
   | Created | Date | When idea was captured |

3. **Share with integration**

### 6.6 Create Database 4: Admin
1. **Add new database**: `Admin`
2. **Configure properties**:
   
   | Property Name | Type | Description | Options |
   |---------------|------|-------------|---------|
   | Name | Title | Task name | |
   | Due Date | Date | When task is due | |
   | Status | Select | Task status | Not Started, In Progress, Done |
   | Notes | Text | Additional details | |
   | Created | Date | When task was added | |

3. **Share with integration**

### 6.7 Create Database 5: Inbox Log
1. **Add new database**: `Inbox Log`
2. **Configure properties**:
   
   | Property Name | Type | Description | Options |
   |---------------|------|-------------|---------|
   | Captured Text | Title | Original Slack message | |
   | Filed To | Select | Destination database | People, Projects, Ideas, Admin |
   | Destination Record | Text | Link to created record | |
   | Confidence Score | Number | AI confidence (0-1) | |
   | Status | Select | Processing status | Filed Successfully, Needs Review, Error |
   | Created | Date | When captured | |

3. **Share with integration**

### 6.8 Get Notion Database IDs
1. **For each database**, click **Share** → **Copy link**
2. **Extract Database ID** from URL:
   ```
   https://www.notion.so/[workspace]/[DATABASE_ID]?v=[view_id]
   ```
   The DATABASE_ID is the 32-character string between workspace and `?v=`
3. **Save all Database IDs** for N8N configuration

## Step 7: System Integration Testing

### 7.1 Test Ollama
```bash
# Test model response
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Classify this message into one of: people, projects, ideas, admin. Message: Call John about the website project",
    "stream": false
  }'
```

### 7.2 Test N8N Access
1. **Open** `http://localhost:5678`
2. **Login** with admin credentials
3. **Verify** Slack and Notion nodes are available

### 7.3 Test Notion API Access
```bash
# Test with your integration token
curl -X GET https://api.notion.com/v1/users \
  -H "Authorization: Bearer YOUR_NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28"
```

### 7.4 Test Slack Integration
1. **Post test message** in #sb-inbox
2. **Verify** message appears
3. **Test bot permissions** by inviting bot to channel

## Step 8: Environment Configuration

### 8.1 Create Environment File

**File: `~/second-brain-infrastructure/.env`**
```bash
# Notion Configuration
NOTION_TOKEN=secret_your_notion_integration_token
NOTION_DB_PEOPLE=your_people_database_id
NOTION_DB_PROJECTS=your_projects_database_id  
NOTION_DB_IDEAS=your_ideas_database_id
NOTION_DB_ADMIN=your_admin_database_id
NOTION_DB_INBOX_LOG=your_inbox_log_database_id

# Slack Configuration
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_WEBHOOK_URL=https://hooks.slack.com/your/webhook/url
SLACK_CHANNEL_ID=your_sb_inbox_channel_id

# Ollama Configuration
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODEL=llama3.2:3b

# N8N Configuration
N8N_HOST=localhost
N8N_PORT=5678
WEBHOOK_URL=http://localhost:5678/
```

### 8.2 Secure Environment File
```bash
# Set proper permissions
chmod 600 ~/second-brain-infrastructure/.env

# Add to .gitignore if using git
echo ".env" >> ~/second-brain-infrastructure/.gitignore
```

## Step 9: System Startup and Monitoring

### 9.1 Create Startup Script

**File: `~/second-brain-infrastructure/start.sh`**
```bash
#!/bin/bash

echo "🧠 Starting Second Brain Infrastructure..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Create network if it doesn't exist
docker network inspect second-brain-net >/dev/null 2>&1 || \
    docker network create second-brain-net

# Start services
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check Ollama
if curl -s http://localhost:11434/api/version > /dev/null; then
    echo "✅ Ollama is healthy"
else
    echo "❌ Ollama is not responding"
fi

# Check N8N
if curl -s http://localhost:5678/healthz > /dev/null; then
    echo "✅ N8N is healthy"
else
    echo "❌ N8N is not responding"
fi

echo ""
echo "🚀 Second Brain Infrastructure Status:"
echo "   Ollama: http://localhost:11434"
echo "   N8N: http://localhost:5678"
echo ""
echo "Next steps:"
echo "1. Configure N8N workflows (Phase 1)"
echo "2. Test end-to-end functionality (Phase 3)"
```

```bash
# Make script executable
chmod +x ~/second-brain-infrastructure/start.sh
```

### 9.2 Create Stop Script

**File: `~/second-brain-infrastructure/stop.sh`**
```bash
#!/bin/bash

echo "🛑 Stopping Second Brain Infrastructure..."

# Stop all services
docker-compose down

echo "✅ All services stopped"
echo ""
echo "Data preserved in:"
echo "   - ./data/n8n (N8N workflows and settings)"
echo "   - ./data/ollama (AI models and cache)"
```

```bash
# Make script executable
chmod +x ~/second-brain-infrastructure/stop.sh
```

## Step 10: Backup and Recovery Setup

### 10.1 Create Backup Script

**File: `~/second-brain-infrastructure/backup.sh`**
```bash
#!/bin/bash

BACKUP_DIR="$HOME/second-brain-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "💾 Creating backup at $BACKUP_PATH"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup N8N data
echo "Backing up N8N data..."
cp -r ./data/n8n "$BACKUP_PATH/"

# Backup environment configuration
echo "Backing up configuration..."
cp .env "$BACKUP_PATH/" 2>/dev/null || echo "No .env file found"
cp docker-compose.yml "$BACKUP_PATH/"

# Create archive
echo "Creating archive..."
cd "$BACKUP_DIR"
tar -czf "second-brain-backup-$TIMESTAMP.tar.gz" "backup_$TIMESTAMP"
rm -rf "backup_$TIMESTAMP"

echo "✅ Backup completed: second-brain-backup-$TIMESTAMP.tar.gz"
echo "Location: $BACKUP_DIR"

# Keep only last 5 backups
ls -t second-brain-backup-*.tar.gz | tail -n +6 | xargs -r rm --

echo "📁 Backup retention: keeping 5 most recent backups"
```

```bash
# Make script executable
chmod +x ~/second-brain-infrastructure/backup.sh
```

## Verification Checklist

### ✅ Infrastructure Verification
- [ ] Docker Desktop installed and running
- [ ] Ollama container running on port 11434
- [ ] N8N container running on port 5678
- [ ] AI model downloaded and functional
- [ ] Container auto-restart configured
- [ ] Docker network created and functional

### ✅ Slack Configuration
- [ ] Slack workspace created/configured
- [ ] SB-Inbox channel created and private
- [ ] Slack app created with proper permissions
- [ ] Bot token obtained and secured
- [ ] Bot added to SB-Inbox channel
- [ ] Webhook URL configured

### ✅ Notion Configuration
- [ ] Notion integration created
- [ ] Integration token obtained and secured
- [ ] Second Brain page created
- [ ] People database created with correct schema
- [ ] Projects database created with correct schema
- [ ] Ideas database created with correct schema
- [ ] Admin database created with correct schema
- [ ] Inbox Log database created with correct schema
- [ ] All databases shared with integration
- [ ] Database IDs extracted and documented

### ✅ System Integration
- [ ] Ollama API responding correctly
- [ ] N8N web interface accessible
- [ ] Notion API accessible with integration token
- [ ] Environment variables configured
- [ ] Backup system in place
- [ ] Startup/stop scripts functional

## Troubleshooting Guide

### Common Issues

#### Ollama Model Download Fails
```bash
# Check available disk space
df -h

# Try pulling a smaller model
docker exec -it second-brain-ollama ollama pull phi3:mini

# Check Ollama logs
docker logs second-brain-ollama
```

#### N8N Won't Start
```bash
# Check port availability
lsof -i :5678

# Check N8N logs
docker logs second-brain-n8n

# Reset N8N data (nuclear option)
rm -rf ./data/n8n/*
docker-compose restart n8n
```

#### Notion API Returns 401
1. **Verify integration token** is correct
2. **Ensure databases are shared** with integration
3. **Check token permissions** in Notion integration settings

#### Slack Bot No Permissions
1. **Verify bot token** is correct (`xoxb-` prefix)
2. **Check bot permissions** in Slack app settings
3. **Ensure bot is added** to SB-Inbox channel
4. **Test with `/invite @YourBot`** in channel

## Security Considerations

### Access Control
- **Environment file** (`.env`) contains sensitive tokens - keep secure
- **Notion databases** should only be shared with the integration
- **Slack workspace** should be private/invite-only
- **Docker containers** run with minimal necessary privileges

### Network Security
- **N8N interface** is only accessible locally (localhost:5678)
- **Ollama API** is only accessible locally (localhost:11434)
- **No external ports** exposed beyond localhost
- **Docker network** isolated from other containers

### Backup Security
- **Backup files** contain sensitive configuration data
- **Store backups** in secure location
- **Encrypt backups** if storing off-device
- **Regular rotation** of API keys/tokens recommended

## Next Steps

After completing this Phase 0 deployment:

1. **Proceed to Phase 1**: Deploy and Configure N8N workflows
2. **Test each component** individually before integration
3. **Document any customizations** made during deployment
4. **Set up monitoring** for container health and resource usage

---

**Deployment Complete!** 🎉

Your Second Brain infrastructure is now ready for workflow configuration and testing.