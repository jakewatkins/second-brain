# Phase 1: Core Ingestion Workflow Deployment Plan

## Overview
This document provides step-by-step instructions for building and deploying the core ingestion workflow for the Second Brain system. This workflow captures messages from Slack, classifies them using Ollama, and files them to the appropriate Notion database.

## Prerequisites

### Completed Phase 0
- ✅ Docker infrastructure running (Ollama + N8N)
- ✅ Slack workspace with SB-Inbox channel configured
- ✅ Notion databases created and shared with integration
- ✅ API tokens and credentials secured in `.env` file

### Required Information
- **Notion Database IDs** (all 5 databases)
- **Slack Bot Token** (`xoxb-...`)
- **Slack Channel ID** for SB-Inbox
- **Ollama Model Name** (e.g., `llama3.2:3b`)

## Workflow Architecture

### Data Flow Diagram
```
┌──────────────────────────────────────────────────────────────┐
│                    CORE INGESTION WORKFLOW                   │
└──────────────────────────────────────────────────────────────┘

1️⃣  Slack Message         →  [Slack Trigger]
    "Call John about             └─ Channel: sb-inbox
     website project"            └─ Event: New Message

2️⃣  Extract Data          →  [Parse Slack Data]
    - Message text               └─ Extract: text, user, timestamp
    - User info                  └─ Extract: channel, thread_ts
    - Timestamp

3️⃣  AI Classification     →  [HTTP Request → Ollama]
    - Send to Ollama            └─ Endpoint: /api/generate
    - Classification prompt     └─ Model: llama3.2:3b
                                └─ Response: JSON

4️⃣  Parse AI Response     →  [Code Node]
    - Extract category          └─ Parse JSON response
    - Extract confidence        └─ Structure data
    - Extract details           └─ Validate fields

5️⃣  Confidence Check      →  [IF Node]
    - High (≥0.7) → Route       └─ TRUE: Auto-file
    - Low (<0.7)  → Review      └─ FALSE: Manual review

6️⃣  Route to Database     →  [Switch Node]
    - People → People DB        └─ Based on category
    - Projects → Projects DB    └─ Dynamic routing
    - Ideas → Ideas DB
    - Admin → Admin DB

7️⃣  Create Notion Entry   →  [Notion Node]
    - Write to database         └─ Create page
    - Set properties            └─ Set all fields
    - Link relationships

8️⃣  Log to Inbox Log      →  [Notion Node]
    - Audit trail               └─ Create audit record
    - Link to destination       └─ Status tracking

9️⃣  Send Confirmation     →  [Slack Node]
    - Reply in thread           └─ Success message
    - Show category             └─ Confidence score
```

## Step 1: Verify Infrastructure Readiness

### 1.1 Check Running Services
```bash
# Navigate to infrastructure directory
cd ~/second-brain-infrastructure

# Start infrastructure if not running
./start.sh

# Verify all services are healthy
docker ps

# Expected output:
# second-brain-n8n    Up (healthy)
# second-brain-ollama Up (healthy)
```

### 1.2 Test Ollama Connectivity
```bash
# Test Ollama API from within N8N container
docker exec second-brain-n8n curl http://second-brain-ollama:11434/api/version

# Test Ollama classification
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Classify this: Call John about the website project",
    "stream": false
  }'
```

### 1.3 Verify N8N Access
```bash
# Open N8N in browser
open http://localhost:5678

# Login with your admin credentials
```

## Step 2: Configure N8N Credentials

### 2.1 Add Slack Credentials
1. **In N8N** → Click **Settings** (⚙️) → **Credentials**
2. **Click** `+ Add Credential`
3. **Search** for "Slack"
4. **Select** `Slack OAuth2 API`
5. **Configure**:
   - **Credential Name**: `Slack - Second Brain`
   - **Access Token**: Paste your Slack Bot Token (`xoxb-...`)
6. **Click** `Save`
7. **Test credential** by clicking `Test`

### 2.2 Add Notion Credentials
1. **In N8N** → **Credentials** → `+ Add Credential`
2. **Search** for "Notion"
3. **Select** `Notion API`
4. **Configure**:
   - **Credential Name**: `Notion - Second Brain`
   - **API Key**: Paste your Notion Integration Token (`secret_...`)
   - **Notion Version**: `2022-06-28`
5. **Click** `Save`
6. **Test credential** by clicking `Test`

### 2.3 Document Notion Database IDs
Create a reference document for quick access:

**File: `~/second-brain-infrastructure/notion-database-ids.txt`**
```
NOTION DATABASE IDs (for N8N configuration)
===========================================

People Database:     [32-character-id-here]
Projects Database:   [32-character-id-here]
Ideas Database:      [32-character-id-here]
Admin Database:      [32-character-id-here]
Inbox Log Database:  [32-character-id-here]

How to find:
1. Open database in Notion
2. Click Share → Copy Link
3. Extract ID from URL: notion.so/[workspace]/[DATABASE_ID]?v=...
```

## Step 3: Create Core Ingestion Workflow

### 3.1 Create New Workflow
1. **In N8N** → Click `+ New Workflow`
2. **Name workflow**: `Slack Inbox Processor`
3. **Save** workflow (Ctrl/Cmd + S)

### 3.2 Add Slack Trigger Node

#### Node Configuration
1. **Click** `+` to add node
2. **Search** for "Slack Trigger"
3. **Select** `Slack Trigger`
4. **Configure**:
   - **Credential**: Select `Slack - Second Brain`
   - **Trigger On**: `Message`
   - **Channel**: Enter your `sb-inbox` channel name or ID
   - **Options** → **Resolve Data**: `true` (to get user info)

#### Test the Trigger
1. **Click** `Listen for Test Event`
2. **Post a message** in Slack #sb-inbox: `"Test message from Slack"`
3. **Verify** N8N captures the message
4. **Examine output** - should show:
   ```json
   {
     "text": "Test message from Slack",
     "user": "U123456",
     "channel": "C789012",
     "ts": "1234567890.123456"
   }
   ```

### 3.3 Add Data Extraction Node

#### Node Configuration
1. **Add** `Function` node after Slack Trigger
2. **Rename node** to: `Extract Slack Data`
3. **Configure** JavaScript code:

```javascript
// Extract and structure Slack message data
const slackData = $input.first().json;

return {
  json: {
    // Original message data
    message_text: slackData.text || slackData.message?.text || '',
    user_id: slackData.user || slackData.message?.user || '',
    user_name: slackData.user_profile?.real_name || 'Unknown User',
    channel_id: slackData.channel || '',
    timestamp: slackData.ts || slackData.message?.ts || '',
    thread_ts: slackData.thread_ts || slackData.ts || '',
    
    // Metadata
    event_time: new Date().toISOString(),
    raw_event: slackData
  }
};
```

4. **Click** `Execute Node` to test
5. **Verify output** shows structured data

### 3.4 Add Ollama Classification Node

#### Node Configuration
1. **Add** `HTTP Request` node
2. **Rename** to: `Ollama - Classify Message`
3. **Configure**:
   - **Authentication**: None
   - **Method**: `POST`
   - **URL**: `http://second-brain-ollama:11434/api/generate`
   - **Send Body**: `true`
   - **Body Content Type**: `JSON`
   - **Specify Body**: `Using JSON`

4. **JSON Body** - Click `Add Parameter` for each:
   ```json
   {
     "model": "llama3.2:3b",
     "prompt": "You are a message classifier for a personal knowledge management system. Classify the following message into one of four categories: people, projects, ideas, or admin.\n\nMessage: {{ $json.message_text }}\n\nExtract relevant details and return ONLY valid JSON in this exact format:\n{\n  \"category\": \"people|projects|ideas|admin\",\n  \"confidence\": 0.85,\n  \"name\": \"extracted title or name\",\n  \"details\": \"relevant context or description\",\n  \"next_action\": \"specific actionable step (only for projects/admin, null for others)\"\n}\n\nRules:\n- People: contacts, relationships, networking, someone mentioned\n- Projects: work tasks, goals, multi-step activities requiring completion\n- Ideas: insights, concepts, inspiration, things to explore later\n- Admin: errands, administrative tasks, appointments, deadlines\n- Return confidence between 0 and 1\n- Use null for next_action if not applicable\n- Return ONLY the JSON, no additional text",
     "stream": false,
     "format": "json"
   }
   ```

5. **Options** → **Response Format**: `JSON`
6. **Options** → **Timeout**: `30000` (30 seconds)

#### Test Classification
1. **Click** `Execute Node`
2. **Verify response** contains:
   ```json
   {
     "model": "llama3.2:3b",
     "created_at": "...",
     "response": "{\"category\":\"projects\",\"confidence\":0.9,...}"
   }
   ```

### 3.5 Add Response Parser Node

#### Node Configuration
1. **Add** `Code` node
2. **Rename** to: `Parse AI Response`
3. **Configure** - Mode: `Run Once for All Items`
4. **JavaScript Code**:

```javascript
// Get data from previous nodes
const slackData = $('Extract Slack Data').first().json;
const ollamaData = $input.first().json;

// Parse Ollama response
let classification;
try {
  // Ollama response is in 'response' field as a JSON string
  const responseText = ollamaData.response || '{}';
  classification = JSON.parse(responseText);
} catch (error) {
  // Fallback if parsing fails
  classification = {
    category: 'admin',
    confidence: 0.3,
    name: slackData.message_text.substring(0, 100),
    details: 'Classification parsing failed',
    next_action: null
  };
}

// Validate confidence is a number between 0 and 1
const confidence = parseFloat(classification.confidence) || 0;
const validConfidence = Math.max(0, Math.min(1, confidence));

// Structure final data
return {
  json: {
    // Original message data
    original_message: slackData.message_text,
    user_id: slackData.user_id,
    user_name: slackData.user_name,
    channel_id: slackData.channel_id,
    timestamp: slackData.timestamp,
    thread_ts: slackData.thread_ts,
    
    // Classification results
    category: classification.category?.toLowerCase() || 'admin',
    confidence: validConfidence,
    entry_name: classification.name || slackData.message_text.substring(0, 100),
    details: classification.details || classification.context || slackData.message_text,
    next_action: classification.next_action || null,
    
    // Metadata
    classified_at: new Date().toISOString(),
    raw_classification: classification
  }
};
```

5. **Click** `Execute Node`
6. **Verify output** shows clean, structured data

### 3.6 Add Confidence Check Node

#### Node Configuration
1. **Add** `If` node
2. **Rename** to: `Check Confidence Threshold`
3. **Configure Conditions**:
   - **Condition**: Number
   - **Value 1**: `{{ $json.confidence }}`
   - **Operation**: `Larger or Equal`
   - **Value 2**: `0.7`

4. **Outputs**:
   - **TRUE branch**: High confidence → Auto-file
   - **FALSE branch**: Low confidence → Manual review

#### Test the Branch
1. **Click** `Execute Node`
2. **Verify** correct branch activates based on confidence
3. **Adjust threshold** if needed (0.6-0.8 recommended)

### 3.7 Add Category Router Node (TRUE Branch)

#### Node Configuration
1. **Connect to TRUE output** of IF node
2. **Add** `Switch` node
3. **Rename** to: `Route by Category`
4. **Mode**: `Expression`
5. **Configure Outputs**:
   - **Output 0**: People
     - Rule: `{{ $json.category }}` equals `people`
   - **Output 1**: Projects
     - Rule: `{{ $json.category }}` equals `projects`
   - **Output 2**: Ideas
     - Rule: `{{ $json.category }}` equals `ideas`
   - **Output 3**: Admin
     - Rule: `{{ $json.category }}` equals `admin`

6. **Fallback Output**: Enabled → Routes to Output 4 (error handling)

## Step 4: Add Notion Database Writers

### 4.1 Create Entry - People Database

#### Node Configuration
1. **Connect to Output 0** (People) of Switch node
2. **Add** `Notion` node
3. **Rename** to: `Notion - Create Person`
4. **Configure**:
   - **Credential**: `Notion - Second Brain`
   - **Resource**: `Database Page`
   - **Operation**: `Create`
   - **Database**: Select `People` database (or paste Database ID)

5. **Page Properties**:
   - **Name** (Title): `{{ $json.entry_name }}`
   - Click `Add Property`:
     - **Property**: `Context`
     - **Type**: `Text`
     - **Value**: `{{ $json.details }}`
   - Click `Add Property`:
     - **Property**: `Last Touched`
     - **Type**: `Date`
     - **Value**: `{{ $json.classified_at }}`
   - Click `Add Property`:
     - **Property**: `Tags`
     - **Type**: `Multi-select`
     - **Value**: `slack-capture`

#### Test the Node
1. **Click** `Execute Node`
2. **Check Notion** - verify new entry appears in People database
3. **Verify all fields** populated correctly

### 4.2 Create Entry - Projects Database

#### Node Configuration
1. **Connect to Output 1** (Projects) of Switch node
2. **Add** `Notion` node
3. **Rename** to: `Notion - Create Project`
4. **Configure**:
   - **Credential**: `Notion - Second Brain`
   - **Resource**: `Database Page`
   - **Operation**: `Create`
   - **Database**: Select `Projects` database

5. **Page Properties**:
   - **Name** (Title): `{{ $json.entry_name }}`
   - Click `Add Property`:
     - **Property**: `Status`
     - **Type**: `Select`
     - **Value**: `Active`
   - Click `Add Property`:
     - **Property**: `Next Action`
     - **Type**: `Text`
     - **Value**: `{{ $json.next_action || $json.details }}`
   - Click `Add Property`:
     - **Property**: `Notes`
     - **Type**: `Text`
     - **Value**: `{{ $json.original_message }}`
   - Click `Add Property`:
     - **Property**: `Created`
     - **Type**: `Date`
     - **Value**: `{{ $json.classified_at }}`
   - Click `Add Property`:
     - **Property**: `Tags`
     - **Type**: `Multi-select`
     - **Value**: `slack-capture`

### 4.3 Create Entry - Ideas Database

#### Node Configuration
1. **Connect to Output 2** (Ideas) of Switch node
2. **Add** `Notion` node
3. **Rename** to: `Notion - Create Idea`
4. **Configure**:
   - **Credential**: `Notion - Second Brain`
   - **Resource**: `Database Page`
   - **Operation**: `Create`
   - **Database**: Select `Ideas` database

5. **Page Properties**:
   - **Name** (Title): `{{ $json.entry_name }}`
   - Click `Add Property`:
     - **Property**: `One-liner`
     - **Type**: `Text`
     - **Value**: `{{ $json.details.substring(0, 200) }}`
   - Click `Add Property`:
     - **Property**: `Notes`
     - **Type**: `Text`
     - **Value**: `{{ $json.original_message }}`
   - Click `Add Property`:
     - **Property**: `Created`
     - **Type**: `Date`
     - **Value**: `{{ $json.classified_at }}`
   - Click `Add Property`:
     - **Property**: `Tags`
     - **Type**: `Multi-select`
     - **Value**: `slack-capture`

### 4.4 Create Entry - Admin Database

#### Node Configuration
1. **Connect to Output 3** (Admin) of Switch node
2. **Add** `Notion` node
3. **Rename** to: `Notion - Create Admin Task`
4. **Configure**:
   - **Credential**: `Notion - Second Brain`
   - **Resource**: `Database Page`
   - **Operation**: `Create`
   - **Database**: Select `Admin` database

5. **Page Properties**:
   - **Name** (Title): `{{ $json.entry_name }}`
   - Click `Add Property`:
     - **Property**: `Status`
     - **Type**: `Select`
     - **Value**: `Not Started`
   - Click `Add Property`:
     - **Property**: `Notes`
     - **Type**: `Text`
     - **Value**: `{{ $json.details }}\n\nOriginal: {{ $json.original_message }}`
   - Click `Add Property`:
     - **Property**: `Created`
     - **Type**: `Date`
     - **Value**: `{{ $json.classified_at }}`

## Step 5: Add Audit Trail (Inbox Log)

### 5.1 Merge Notion Outputs
1. **Add** `Merge` node after all 4 Notion creation nodes
2. **Rename** to: `Merge All Entries`
3. **Configure**:
   - **Mode**: `Combine All`
   - **Connect** all 4 Notion nodes to this Merge node

### 5.2 Extract Notion Page ID

#### Node Configuration
1. **Add** `Code` node after Merge
2. **Rename** to: `Extract Page Details`
3. **JavaScript Code**:

```javascript
// Get the created Notion page data
const notionResponse = $input.first().json;
const previousData = $('Parse AI Response').first().json;

// Extract Notion page URL
const pageId = notionResponse.id || 'unknown';
const pageUrl = notionResponse.url || `https://notion.so/${pageId.replace(/-/g, '')}`;

return {
  json: {
    // Carry forward all previous data
    ...previousData,
    
    // Add Notion page details
    notion_page_id: pageId,
    notion_page_url: pageUrl,
    filing_status: 'Filed Successfully'
  }
};
```

### 5.3 Create Inbox Log Entry

#### Node Configuration
1. **Add** `Notion` node
2. **Rename** to: `Notion - Log to Inbox`
3. **Configure**:
   - **Credential**: `Notion - Second Brain`
   - **Resource**: `Database Page`
   - **Operation**: `Create`
   - **Database**: Select `Inbox Log` database

4. **Page Properties**:
   - **Captured Text** (Title): `{{ $json.original_message }}`
   - Click `Add Property`:
     - **Property**: `Filed To`
     - **Type**: `Select`
     - **Value**: `{{ $json.category }}`
   - Click `Add Property`:
     - **Property**: `Destination Record`
     - **Type**: `URL` or `Text`
     - **Value**: `{{ $json.notion_page_url }}`
   - Click `Add Property`:
     - **Property**: `Confidence Score`
     - **Type**: `Number`
     - **Value**: `{{ $json.confidence }}`
   - Click `Add Property`:
     - **Property**: `Status`
     - **Type**: `Select`
     - **Value**: `Filed Successfully`
   - Click `Add Property`:
     - **Property**: `Created`
     - **Type**: `Date`
     - **Value**: `{{ $json.classified_at }}`

## Step 6: Add Slack Confirmation Reply

### 6.1 Success Confirmation (TRUE Branch)

#### Node Configuration
1. **Add** `Slack` node after Inbox Log
2. **Rename** to: `Slack - Success Reply`
3. **Configure**:
   - **Credential**: `Slack - Second Brain`
   - **Resource**: `Message`
   - **Operation**: `Post`
   - **Channel**: `{{ $json.channel_id }}`
   - **Text**: 
     ```
     ✅ *Filed to {{ $json.category }}*
     
     📝 *{{ $json.entry_name }}*
     🎯 Confidence: {{ Math.round($json.confidence * 100) }}%
     
     <{{ $json.notion_page_url }}|View in Notion>
     ```
   - **Options** → **Thread TS**: `{{ $json.thread_ts }}`
   - **Options** → **Reply Broadcast**: `false`

### 6.2 Low Confidence Handler (FALSE Branch)

#### Node Configuration
1. **Connect to FALSE output** of IF node
2. **Add** `Notion` node
3. **Rename** to: `Notion - Log Needs Review`
4. **Configure** similar to Inbox Log but:
   - **Status**: `Needs Review` (instead of "Filed Successfully")
   - **Do NOT** set `Destination Record` (leave empty)

5. **Add** `Slack` node after this Notion node
6. **Rename** to: `Slack - Review Needed Reply`
7. **Configure**:
   - **Credential**: `Slack - Second Brain`
   - **Resource**: `Message`
   - **Operation**: `Post`
   - **Channel**: `{{ $json.channel_id }}`
   - **Text**:
     ```
     ⚠️ *Low confidence classification*
     
     📝 *Message:* {{ $json.original_message }}
     
     🤔 *Suggested:* {{ $json.category }} ({{ Math.round($json.confidence * 100) }}% confidence)
     
     *Please categorize manually:*
     Reply with: `people`, `projects`, `ideas`, or `admin`
     ```
   - **Options** → **Thread TS**: `{{ $json.thread_ts }}`

## Step 7: Add Error Handling

### 7.1 Add Error Trigger
1. **Click** workflow settings (⚙️)
2. **Settings** → **Error Workflow**
3. **Create new error workflow** or select existing
4. **Configure** error logging to Notion Inbox Log

### 7.2 Add Try-Catch Wrapper (Optional)
For production robustness, wrap critical nodes:

1. **Select** Ollama classification node
2. **Settings** → **Continue On Fail**: `true`
3. **Add** `If` node checking for errors
4. **Route errors** to manual review path

## Step 8: Testing and Validation

### 8.1 End-to-End Test - People
```
Test Message in Slack:
"Met Sarah Johnson at the DevOps conference - she's a platform engineer at Acme Corp, interested in infrastructure automation"

Expected Result:
✅ Filed to People database
✅ Name: "Sarah Johnson"
✅ Context contains conference info
✅ Inbox Log entry created
✅ Slack confirmation posted
```

### 8.2 End-to-End Test - Projects
```
Test Message in Slack:
"Need to refactor the authentication module to support OAuth2 and add unit tests"

Expected Result:
✅ Filed to Projects database
✅ Status: Active
✅ Next Action populated
✅ Inbox Log entry created
✅ Slack confirmation posted
```

### 8.3 End-to-End Test - Ideas
```
Test Message in Slack:
"What if we used event sourcing for the audit log instead of traditional CRUD? Would give us complete history replay capability"

Expected Result:
✅ Filed to Ideas database
✅ One-liner extracted
✅ Notes contain full thought
✅ Inbox Log entry created
✅ Slack confirmation posted
```

### 8.4 End-to-End Test - Admin
```
Test Message in Slack:
"Schedule dentist appointment for next Tuesday, renew car registration by end of month"

Expected Result:
✅ Filed to Admin database
✅ Status: Not Started
✅ Inbox Log entry created
✅ Slack confirmation posted
```

### 8.5 Test Low Confidence Handling
```
Test Message in Slack:
"asdf qwer zxcv" (gibberish)

Expected Result:
✅ Routed to review path
✅ Inbox Log status: Needs Review
✅ Slack asks for manual categorization
❌ NOT auto-filed to any database
```

## Step 9: Workflow Optimization

### 9.1 Performance Tuning
```javascript
// In Ollama HTTP Request node, adjust timeout
Options → Timeout: 60000 (1 minute for slower models)

// In Classification prompt, add response format hint
"Respond within 5 seconds with only JSON, no markdown formatting"
```

### 9.2 Add Workflow Metadata
1. **Click** workflow settings
2. **Add tags**: `production`, `core`, `slack-integration`
3. **Add description**:
   ```
   Core ingestion workflow for Second Brain.
   Captures Slack messages, classifies with Ollama, files to Notion.
   
   Last updated: [date]
   Confidence threshold: 0.7
   Model: llama3.2:3b
   ```

### 9.3 Enable Workflow Execution Logging
1. **Settings** → **Execution Settings**
2. **Save Execution Progress**: `true`
3. **Save Data on Success**: `true`
4. **Save Data on Error**: `true`
5. **Save Manual Executions**: `true`

## Step 10: Activate and Monitor

### 10.1 Activate Workflow
1. **Click** the **Inactive** toggle in top right
2. **Verify** it shows **Active** (green)
3. **Workflow** is now live and listening for Slack messages

### 10.2 Monitor First Real Captures
```bash
# Watch N8N logs
docker logs -f second-brain-n8n

# Watch for execution activity
# Open N8N → Executions tab → Monitor incoming messages
```

### 10.3 Verify Data Flow
1. **Post real message** in Slack #sb-inbox
2. **Check N8N Executions** - should show successful run
3. **Verify Notion** - entry in appropriate database
4. **Check Inbox Log** - audit record created
5. **Confirm Slack** - reply posted in thread

## Verification Checklist

### ✅ Credentials & Configuration
- [ ] Slack credentials configured and tested
- [ ] Notion credentials configured and tested
- [ ] All 5 Notion Database IDs documented
- [ ] Ollama connectivity verified from N8N
- [ ] Confidence threshold set (default: 0.7)

### ✅ Workflow Nodes
- [ ] Slack Trigger capturing messages
- [ ] Data extraction structuring message correctly
- [ ] Ollama classification returning JSON
- [ ] Response parser handling output correctly
- [ ] Confidence check routing properly
- [ ] Category router directing to correct database
- [ ] All 4 Notion writers creating entries
- [ ] Inbox Log audit trail working
- [ ] Slack confirmations posting in threads

### ✅ Testing
- [ ] People category test passed
- [ ] Projects category test passed
- [ ] Ideas category test passed
- [ ] Admin category test passed
- [ ] Low confidence handling verified
- [ ] Error handling tested
- [ ] End-to-end flow validated

### ✅ Production Readiness
- [ ] Workflow activated
- [ ] Execution logging enabled
- [ ] Error handling configured
- [ ] Performance acceptable (<30s per message)
- [ ] Monitoring in place

## Troubleshooting Guide

### Issue: Slack Trigger Not Firing

**Symptoms:**
- Messages posted to Slack but N8N doesn't capture them
- No executions showing in N8N Executions tab

**Solutions:**
```bash
# 1. Verify bot is in channel
# In Slack #sb-inbox, type:
/invite @Second Brain N8N

# 2. Check Slack credential permissions
# In Slack API settings, verify scopes:
- channels:read
- channels:history
- chat:write

# 3. Check N8N logs
docker logs second-brain-n8n | grep -i slack

# 4. Re-save Slack Trigger node
# Sometimes N8N needs webhook re-registration
```

### Issue: Ollama Not Responding

**Symptoms:**
- HTTP Request node times out
- Error: "ECONNREFUSED" or "Network error"

**Solutions:**
```bash
# 1. Verify Ollama is running
docker ps | grep ollama

# 2. Test Ollama from N8N container
docker exec second-brain-n8n curl http://second-brain-ollama:11434/api/version

# 3. Check if model is loaded
docker exec second-brain-ollama ollama list

# 4. Restart Ollama container
docker restart second-brain-ollama

# 5. Check Ollama logs
docker logs second-brain-ollama
```

### Issue: Notion Database Not Found

**Symptoms:**
- Error: "Database not found" or "Unauthorized"
- Notion node fails to create entries

**Solutions:**
```bash
# 1. Verify database is shared with integration
# In Notion, click database Share button
# Ensure "Second Brain N8N" integration is listed

# 2. Verify Database ID is correct
# Database ID should be 32 characters (no dashes)

# 3. Test Notion API directly
curl https://api.notion.com/v1/databases/YOUR_DATABASE_ID \
  -H "Authorization: Bearer YOUR_NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28"

# 4. Re-share databases with integration
# Sometimes permissions need to be refreshed
```

### Issue: Classification Always Low Confidence

**Symptoms:**
- All messages routed to manual review
- Confidence scores consistently < 0.7

**Solutions:**
```javascript
// 1. Adjust prompt to be more explicit
// Add to prompt:
"Be confident in your classification. Only use confidence below 0.7 for truly ambiguous messages."

// 2. Lower threshold temporarily
// In IF node, change threshold from 0.7 to 0.6

// 3. Try different Ollama model
docker exec second-brain-ollama ollama pull mistral:7b
// Update model in HTTP Request node

// 4. Check prompt formatting
// Ensure no extra spaces/newlines breaking JSON parsing
```

### Issue: Slack Confirmation Not Posted

**Symptoms:**
- Workflow succeeds but no reply in Slack
- Thread reply missing

**Solutions:**
```javascript
// 1. Verify thread_ts is correct
// In Slack node, check expression:
{{ $json.thread_ts }}

// 2. Check Slack bot permissions
// Needs: chat:write

// 3. Verify channel_id format
// Should be like: C01234567

// 4. Test Slack API manually
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer YOUR_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "YOUR_CHANNEL_ID",
    "text": "Test message"
  }'
```

## Performance Metrics (DORA Alignment)

### Deployment Frequency
- **Target**: Workflow updates can be deployed multiple times per day
- **Current**: Manual workflow edits in N8N UI
- **Next Phase**: Implement GitOps workflow deployment (covered in API instructions)

### Lead Time for Changes
- **Target**: < 30 seconds from Slack message to Notion entry
- **Measure**: Check N8N execution duration
- **Optimize**: If > 30s, consider faster Ollama model or caching

### Change Failure Rate
- **Target**: < 5% of messages fail classification
- **Measure**: 
  ```sql
  SELECT 
    COUNT(*) FILTER (WHERE status = 'Error') * 100.0 / COUNT(*) as failure_rate
  FROM inbox_log
  WHERE created >= NOW() - INTERVAL '7 days'
  ```
- **Monitor**: Check Inbox Log "Error" status entries weekly

### Mean Time to Recovery
- **Target**: < 15 minutes to detect and fix workflow issues
- **Measure**: Time from error to workflow fix
- **Improve**: Set up N8N error notifications to Slack

## Next Steps

After completing Phase 1:

1. **Use the workflow daily** for 1-2 weeks (Phase 5: Pilot)
2. **Monitor classification accuracy** in Inbox Log
3. **Refine prompts** based on real-world results
4. **Adjust confidence threshold** if needed
5. **Proceed to Phase 2**: Implement audit and quality improvements
6. **Proceed to Phase 3**: Add daily/weekly digest workflows

---

**Phase 1 Complete!** 🎉

Your Second Brain can now automatically capture, classify, and organize your thoughts from Slack into Notion.
