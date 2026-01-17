#!/bin/bash

echo "🛑 Stopping Second Brain Infrastructure..."

# Stop all services
docker-compose down

echo "✅ All services stopped"
echo ""
echo "Data preserved in:"
echo "   - ./data/n8n (N8N workflows and settings)"
echo "   - ./data/ollama (AI models and cache)"
