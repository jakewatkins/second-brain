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
docker-compose -f nolama-docker-compose.yml up -d

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
