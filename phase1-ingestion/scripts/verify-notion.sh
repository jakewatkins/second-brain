#!/bin/bash

# Verify Notion Database Setup
# Checks that all required databases exist and are accessible

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verifying Notion Database Setup${NC}"
echo "===================================="
echo ""

# Check for .env file
if [ ! -f "../../phase0-infrastructure/.env" ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "   Expected location: phase0-infrastructure/.env"
    echo "   Create it following Phase 0 setup instructions"
    exit 1
fi

# Load environment variables
source ../../phase0-infrastructure/.env

# Check for Notion token
if [ -z "$NOTION_TOKEN" ]; then
    echo -e "${RED}❌ NOTION_TOKEN not set in .env file${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found Notion token${NC}"
echo ""

# Test Notion API connection
echo -e "${YELLOW}Testing Notion API connection...${NC}"
API_TEST=$(curl -s -w "\n%{http_code}" \
  -X GET https://api.notion.com/v1/users/me \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28")

HTTP_CODE=$(echo "$API_TEST" | tail -n1)
RESPONSE=$(echo "$API_TEST" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Notion API connection successful${NC}"
    BOT_NAME=$(echo "$RESPONSE" | jq -r '.bot.owner.user.name // "Unknown"')
    echo "   Integration: $BOT_NAME"
else
    echo -e "${RED}❌ Notion API connection failed (HTTP $HTTP_CODE)${NC}"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo ""
echo -e "${YELLOW}Checking databases...${NC}"
echo ""

# Database check function
check_database() {
    local db_name=$1
    local db_id_var=$2
    local db_id=${!db_id_var}
    
    echo -n "   $db_name: "
    
    if [ -z "$db_id" ]; then
        echo -e "${YELLOW}⚠️  Not configured${NC}"
        echo "      Set $db_id_var in .env file"
        return 1
    fi
    
    # Test database access
    DB_TEST=$(curl -s -w "\n%{http_code}" \
      -X GET "https://api.notion.com/v1/databases/$db_id" \
      -H "Authorization: Bearer $NOTION_TOKEN" \
      -H "Notion-Version: 2022-06-28")
    
    HTTP_CODE=$(echo "$DB_TEST" | tail -n1)
    RESPONSE=$(echo "$DB_TEST" | sed '$d')
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        DB_TITLE=$(echo "$RESPONSE" | jq -r '.title[0].plain_text // "Untitled"')
        echo -e "${GREEN}✅ $DB_TITLE${NC}"
        
        # Check properties
        PROPS=$(echo "$RESPONSE" | jq -r '.properties | keys | .[]' | wc -l)
        echo "      Properties: $PROPS configured"
        return 0
    else
        echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
        ERROR=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')
        echo "      Error: $ERROR"
        
        if [ "$HTTP_CODE" -eq 404 ]; then
            echo "      Database not found - check ID is correct"
        elif [ "$HTTP_CODE" -eq 401 ]; then
            echo "      Unauthorized - database may not be shared with integration"
        fi
        return 1
    fi
}

# Check all required databases
SUCCESS=0
TOTAL=5

check_database "People Database    " "NOTION_DB_PEOPLE" && ((SUCCESS++)) || true
check_database "Projects Database  " "NOTION_DB_PROJECTS" && ((SUCCESS++)) || true
check_database "Ideas Database     " "NOTION_DB_IDEAS" && ((SUCCESS++)) || true
check_database "Admin Database     " "NOTION_DB_ADMIN" && ((SUCCESS++)) || true
check_database "Inbox Log Database " "NOTION_DB_INBOX_LOG" && ((SUCCESS++)) || true

echo ""
echo "────────────────────────────────────"
echo -e "Databases: ${GREEN}$SUCCESS${NC}/$TOTAL configured and accessible"

if [ $SUCCESS -eq $TOTAL ]; then
    echo ""
    echo -e "${GREEN}🎉 All databases ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Import N8N workflow: workflows/slack-inbox-processor.json"
    echo "2. Configure N8N credentials (see Phase1-deployment.plan.md Step 2)"
    echo "3. Run end-to-end tests"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠️  Some databases need attention${NC}"
    echo ""
    echo "To fix missing databases:"
    echo "1. Follow Phase 0 Step 6 to create databases in Notion"
    echo "2. Share each database with your N8N integration"
    echo "3. Add database IDs to phase0-infrastructure/.env"
    echo "4. Run this script again to verify"
    exit 1
fi
