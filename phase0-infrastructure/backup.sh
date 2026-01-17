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
