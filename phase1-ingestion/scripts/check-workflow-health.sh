#!/bin/bash

# Check Workflow Health
# Monitors N8N workflow execution and system health

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏥 Second Brain Health Check${NC}"
echo "=============================="
echo ""

# Check Docker containers
echo -e "${YELLOW}1️⃣  Checking Docker containers...${NC}"

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running${NC}"
    exit 1
fi

# Check Ollama
if docker ps | grep -q "second-brain-ollama"; then
    OLLAMA_STATUS=$(docker inspect second-brain-ollama --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$OLLAMA_STATUS" = "healthy" ] || [ "$OLLAMA_STATUS" = "unknown" ]; then
        echo -e "   Ollama:  ${GREEN}✅ Running${NC}"
    else
        echo -e "   Ollama:  ${YELLOW}⚠️  Running but unhealthy${NC}"
    fi
else
    echo -e "   Ollama:  ${RED}❌ Not running${NC}"
fi

# Check N8N
if docker ps | grep -q "second-brain-n8n"; then
    N8N_STATUS=$(docker inspect second-brain-n8n --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$N8N_STATUS" = "healthy" ] || [ "$N8N_STATUS" = "unknown" ]; then
        echo -e "   N8N:     ${GREEN}✅ Running${NC}"
    else
        echo -e "   N8N:     ${YELLOW}⚠️  Running but unhealthy${NC}"
    fi
else
    echo -e "   N8N:     ${RED}❌ Not running${NC}"
fi

echo ""

# Test Ollama API
echo -e "${YELLOW}2️⃣  Testing Ollama API...${NC}"
if curl -s http://localhost:11434/api/version > /dev/null; then
    echo -e "   ${GREEN}✅ Ollama API responding${NC}"
    
    # Check loaded models
    MODEL_COUNT=$(docker exec second-brain-ollama ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    echo "   Models loaded: $MODEL_COUNT"
else
    echo -e "   ${RED}❌ Ollama API not responding${NC}"
fi

echo ""

# Test N8N API
echo -e "${YELLOW}3️⃣  Testing N8N API...${NC}"
if curl -s http://localhost:5678/healthz > /dev/null; then
    echo -e "   ${GREEN}✅ N8N API responding${NC}"
    echo "   URL: http://localhost:5678"
else
    echo -e "   ${RED}❌ N8N API not responding${NC}"
fi

echo ""

# Check recent N8N executions (if we can access logs)
echo -e "${YELLOW}4️⃣  Checking recent activity...${NC}"

# Count recent log entries (last 5 minutes)
RECENT_LOGS=$(docker logs --since 5m second-brain-n8n 2>&1 | wc -l | tr -d ' ')
if [ "$RECENT_LOGS" -gt 0 ]; then
    echo "   Log entries (last 5 min): $RECENT_LOGS"
    
    # Check for errors
    ERROR_COUNT=$(docker logs --since 5m second-brain-n8n 2>&1 | grep -i "error" | wc -l | tr -d ' ')
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Found $ERROR_COUNT error entries${NC}"
    else
        echo -e "   ${GREEN}✅ No errors in recent logs${NC}"
    fi
else
    echo "   No recent activity"
fi

echo ""

# System resources
echo -e "${YELLOW}5️⃣  Resource usage...${NC}"

# Ollama memory usage
OLLAMA_MEM=$(docker stats second-brain-ollama --no-stream --format "{{.MemUsage}}" 2>/dev/null | cut -d'/' -f1 || echo "N/A")
echo "   Ollama memory: $OLLAMA_MEM"

# N8N memory usage
N8N_MEM=$(docker stats second-brain-n8n --no-stream --format "{{.MemUsage}}" 2>/dev/null | cut -d'/' -f1 || echo "N/A")
echo "   N8N memory: $N8N_MEM"

echo ""
echo "────────────────────────────────────"

# Overall health status
OLLAMA_OK=$(docker ps | grep -q "second-brain-ollama" && echo 1 || echo 0)
N8N_OK=$(docker ps | grep -q "second-brain-n8n" && echo 1 || echo 0)
OLLAMA_API_OK=$(curl -s http://localhost:11434/api/version > /dev/null && echo 1 || echo 0)
N8N_API_OK=$(curl -s http://localhost:5678/healthz > /dev/null && echo 1 || echo 0)

HEALTH_SCORE=$((OLLAMA_OK + N8N_OK + OLLAMA_API_OK + N8N_API_OK))

if [ $HEALTH_SCORE -eq 4 ]; then
    echo -e "${GREEN}🎉 All systems healthy!${NC}"
    echo ""
    echo "You can now:"
    echo "  • Access N8N: http://localhost:5678"
    echo "  • Test Ollama: ./scripts/test-ollama.sh"
    echo "  • Verify Notion: ./scripts/verify-notion.sh"
    exit 0
elif [ $HEALTH_SCORE -ge 2 ]; then
    echo -e "${YELLOW}⚠️  System partially healthy ($HEALTH_SCORE/4 checks passed)${NC}"
    echo ""
    echo "Check the failed components above and:"
    echo "  • Restart infrastructure: cd ../phase0-infrastructure && ./start.sh"
    echo "  • Check Docker logs: docker logs second-brain-n8n"
    exit 1
else
    echo -e "${RED}❌ System unhealthy ($HEALTH_SCORE/4 checks passed)${NC}"
    echo ""
    echo "To fix:"
    echo "  1. Ensure Docker Desktop is running"
    echo "  2. Start infrastructure: cd ../phase0-infrastructure && ./start.sh"
    echo "  3. Check logs for errors: docker-compose logs"
    exit 1
fi
