#!/bin/bash

# Test Ollama Classification
# Tests the Ollama API and classification prompt with sample messages

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${OLLAMA_MODEL:-llama3.2:3b}"

echo -e "${BLUE}🧪 Testing Ollama Classification${NC}"
echo "=================================="
echo ""

# Check if message provided as argument
if [ $# -eq 0 ]; then
    MESSAGE="Call John about the website project"
    echo -e "${YELLOW}No message provided, using default test message${NC}"
else
    MESSAGE="$1"
fi

echo -e "${BLUE}Testing message:${NC} \"$MESSAGE\""
echo ""

# Check Ollama availability
echo -e "${YELLOW}1️⃣  Checking Ollama availability...${NC}"
if curl -s "${OLLAMA_URL}/api/version" > /dev/null; then
    VERSION=$(curl -s "${OLLAMA_URL}/api/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✅ Ollama is running (version: ${VERSION})${NC}"
else
    echo -e "${RED}❌ Ollama is not responding at ${OLLAMA_URL}${NC}"
    echo "   Make sure infrastructure is running: cd ../phase0-infrastructure && ./start.sh"
    exit 1
fi

# Check if model exists
echo ""
echo -e "${YELLOW}2️⃣  Checking if model '${MODEL}' is available...${NC}"
if docker exec second-brain-ollama ollama list | grep -q "${MODEL}"; then
    echo -e "${GREEN}✅ Model '${MODEL}' is available${NC}"
else
    echo -e "${RED}❌ Model '${MODEL}' not found${NC}"
    echo "   Pull the model: docker exec -it second-brain-ollama ollama pull ${MODEL}"
    exit 1
fi

# Test classification
echo ""
echo -e "${YELLOW}3️⃣  Running classification...${NC}"

PROMPT="You are a message classifier for a personal knowledge management system. Classify the following message into one of four categories: people, projects, ideas, or admin.

Message: ${MESSAGE}

Extract relevant details and return ONLY valid JSON in this exact format:
{
  \"category\": \"people|projects|ideas|admin\",
  \"confidence\": 0.85,
  \"name\": \"extracted title or name\",
  \"details\": \"relevant context or description\",
  \"next_action\": \"specific actionable step (only for projects/admin, null for others)\"
}

Rules:
- People: contacts, relationships, networking, someone mentioned
- Projects: work tasks, goals, multi-step activities requiring completion
- Ideas: insights, concepts, inspiration, things to explore later
- Admin: errands, administrative tasks, appointments, deadlines
- Return confidence between 0 and 1
- Use null for next_action if not applicable
- Return ONLY the JSON, no additional text or markdown formatting"

START_TIME=$(date +%s)

RESPONSE=$(curl -s -X POST "${OLLAMA_URL}/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL}\",
    \"prompt\": $(echo "$PROMPT" | jq -Rs .),
    \"stream\": false,
    \"format\": \"json\"
  }")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Parse response
if echo "$RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Received valid JSON response${NC}"
    
    # Extract the classification from response
    CLASSIFICATION=$(echo "$RESPONSE" | jq -r '.response')
    
    echo ""
    echo -e "${BLUE}📊 Classification Result:${NC}"
    echo "─────────────────────────"
    echo "$CLASSIFICATION" | jq '.'
    
    echo ""
    echo -e "${BLUE}⏱️  Performance:${NC}"
    echo "   Response time: ${DURATION} seconds"
    
    # Extract key fields
    CATEGORY=$(echo "$CLASSIFICATION" | jq -r '.category // "unknown"')
    CONFIDENCE=$(echo "$CLASSIFICATION" | jq -r '.confidence // 0')
    
    echo ""
    echo -e "${BLUE}📝 Summary:${NC}"
    echo "   Category: ${CATEGORY}"
    echo "   Confidence: ${CONFIDENCE}"
    
    # Confidence assessment
    CONF_PERCENT=$(echo "$CONFIDENCE * 100" | bc | cut -d'.' -f1)
    if (( $(echo "$CONFIDENCE >= 0.7" | bc -l) )); then
        echo -e "   ${GREEN}✅ High confidence - would auto-file${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Low confidence - would need review${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Test completed successfully!${NC}"
    
else
    echo -e "${RED}❌ Failed to parse Ollama response${NC}"
    echo ""
    echo "Raw response:"
    echo "$RESPONSE"
    exit 1
fi

echo ""
echo "────────────────────────────────────"
echo "Try testing with your own message:"
echo "  ./test-ollama.sh \"Your message here\""
