# Second Brain Requirements

## Overview
Implementation of a personal knowledge management system (second brain) using self-hosted N8N, Notion, Slack, and self-hosted Ollama. The system automates the capture, classification, storage, and surfacing of ideas, projects, people, and administrative tasks.

## Core Architecture

### Technology Stack
- **N8N**: Self-hosted workflow automation platform
- **Slack**: Capture interface (SB-Inbox channel)
- **Notion**: Storage layer (5 databases)
- **Ollama**: Self-hosted AI for classification and processing

### Data Flow
1. **Input**: Ideas posted to Slack SB-Inbox channel
2. **Processing**: N8N workflows trigger Ollama for classification
3. **Storage**: Structured data written to appropriate Notion databases
4. **Output**: Daily/weekly digests delivered via Slack DMs

## Notion Database Requirements

### 1. People Database
**Fields:**
- Name (Title)
- Context (Text) - How you know them
- Follow-ups (Text) - Things to remember for next interaction
- Last Touched (Date) - When entry was last updated
- Tags (Multi-select)

### 2. Projects Database
**Fields:**
- Name (Title)
- Status (Select: Active, Waiting, Blocked, Someday, Done)
- Next Action (Text) - Specific executable step
- Notes (Text)
- Tags (Multi-select)
- Created (Date)

### 3. Ideas Database
**Fields:**
- Name (Title)
- One-liner (Text) - Core insight summary
- Notes (Text) - Elaboration space
- Tags (Multi-select)
- Created (Date)

### 4. Admin Database
**Fields:**
- Name (Title)
- Due Date (Date)
- Status (Select: Not Started, In Progress, Done)
- Notes (Text)
- Created (Date)

### 5. Inbox Log Database (Audit Trail)
**Fields:**
- Captured Text (Text) - Original Slack message
- Filed To (Select: People, Projects, Ideas, Admin)
- Destination Record (Text) - Link to created record
- Confidence Score (Number) - AI classification confidence (0-1)
- Created (Date)
- Status (Select: Filed Successfully, Needs Review, Error)

## Core Workflows

### 1. Ingestion Workflow (Primary)
**Trigger**: New message in Slack SB-Inbox channel
**Steps:**
1. Capture Slack message content
2. Send to Ollama with classification prompt
3. Parse JSON response from Ollama
4. Check confidence threshold (≥ 0.6)
5. **If confidence ≥ 0.6**: Route to appropriate Notion database
6. **If confidence < 0.6**: Log in Inbox with "Needs Review" status
7. Create audit record in Inbox Log
8. Send Slack thread reply confirming action

### 2. Daily Digest Workflow
**Trigger**: Scheduled daily (user-defined morning time)
**Steps:**
1. Query Notion databases for:
   - Active projects
   - People with noted follow-ups
   - Admin tasks due soon
2. Send compiled data to Ollama with summarization prompt
3. Generate digest (≤150 words) containing:
   - Top 3 actions for today
   - One item potentially being avoided
   - One small win to notice
4. Send digest via Slack DM

### 3. Weekly Review Workflow
**Trigger**: Scheduled weekly (Sundays, user-defined time)
**Steps:**
1. Query Inbox Log for past 7 days
2. Query all active projects
3. Send data to Ollama with review prompt
4. Generate summary (≤250 words) containing:
   - What happened this week
   - Biggest open loops
   - Three suggested actions for next week
   - One recurring theme noticed
5. Send summary via Slack DM

### 4. Error Correction Workflow
**Trigger**: Slack thread reply starting with "fix:"
**Steps:**
1. Parse correction instruction
2. Update relevant Notion record
3. Update Inbox Log with correction note
4. Send confirmation reply

## AI Prompts

### Classification Prompt (Ollama)
```
You are a message classifier for a personal knowledge management system. Classify the following message into one of four categories: people, projects, ideas, or admin.

Message: {slack_message}

Extract relevant details and return ONLY valid JSON in this exact format:
{
  "category": "people|projects|ideas|admin",
  "confidence": 0.85,
  "name": "extracted title/name",
  "details": "relevant context or description",
  "next_action": "specific actionable step (only for projects/admin, null for others)"
}

Rules:
- People: contacts, relationships, networking, someone mentioned
- Projects: work tasks, goals, multi-step activities requiring completion
- Ideas: insights, concepts, inspiration, things to explore later
- Admin: errands, administrative tasks, appointments, deadlines
- Return confidence between 0 and 1
- Use null for next_action if not applicable
```

### Daily Digest Prompt (Ollama)
```
Create a daily digest from this personal knowledge data. Format as a brief, actionable summary under 150 words.

Data: {notion_query_results}

Generate exactly this format:

**Today's Focus**
• [Action 1 - specific and executable]
• [Action 2 - specific and executable]  
• [Action 3 - specific and executable]

**Attention Check**
• [One thing you might be avoiding or stuck on]

**Small Win**
• [One positive thing to acknowledge]

Keep it phone-readable and energizing.
```

### Weekly Review Prompt (Ollama)
```
Create a weekly review from this week's captured thoughts and current projects. Keep under 250 words.

Inbox activity: {inbox_log_data}
Active projects: {projects_data}

Generate exactly this format:

**This Week's Activity**
[2-3 sentences summarizing what happened]

**Open Loops** 
• [Biggest incomplete item 1]
• [Biggest incomplete item 2]

**Next Week's Focus**
• [Suggested action 1]
• [Suggested action 2]
• [Suggested action 3]

**Pattern Noticed**
[One recurring theme or insight from the week]
```

## System Architecture Principles

### 1. Single Capture Point
- Only one input method: Slack SB-Inbox channel
- No decisions required at capture time
- 5-second maximum capture effort

### 2. Separation of Concerns
- **Memory**: Notion databases (data storage)
- **Compute**: N8N + Ollama (processing logic)
- **Interface**: Slack (human interaction)

### 3. Trust Mechanisms
- Complete audit trail in Inbox Log
- Confidence scoring for all classifications
- Easy error correction via Slack replies
- Transparent logging of all actions

### 4. Graceful Failure Handling
- Low confidence items held for review (don't auto-file)
- Clear error messages in Slack
- System continues operating even with failures
- Easy restart capability after downtime

## Technical Requirements

### N8N Configuration
- **Self-hosted instance** with persistent storage
- **Slack integration** configured for SB-Inbox channel
- **Notion API integration** with write permissions to all databases
- **Ollama integration** via HTTP requests
- **Scheduled workflow capability** for daily/weekly automations
- **JSON parsing and conditional routing** capabilities

### Ollama Configuration
- **Local instance** with suitable model (e.g., llama3, mistral)
- **API endpoint** accessible to N8N
- **Sufficient context window** for classification prompts
- **Consistent JSON output formatting**

### Slack Configuration
- **Private SB-Inbox channel** for captures
- **Bot permissions** for N8N to read messages and post replies
- **Thread reply capability** for confirmations and corrections
- **DM permissions** for digest delivery

### Notion Configuration
- **API integration** with N8N
- **Database permissions** for read/write access
- **Proper field types** configured for each database
- **Relationships/links** between Inbox Log and target databases

## Success Metrics

### System Health
- **Classification accuracy**: >85% of items filed correctly
- **Response time**: <30 seconds from Slack post to Notion filing
- **Uptime**: >95% availability for ingestion workflow
- **Error rate**: <5% of ingestions fail

### User Adoption
- **Daily usage**: Consistent posting to SB-Inbox
- **Trust maintenance**: Low correction rate, continued usage
- **Cognitive relief**: Reduced mental overhead for idea tracking
- **Weekly engagement**: Regular consumption of digest content

## Optional Future Enhancements

### Core System Extensions
- **Voice capture**: Audio message processing
- **Email forwarding**: Email-to-Slack integration
- **Calendar integration**: Meeting prep from People database
- **File attachment** handling in Slack messages
- **Mobile shortcuts** for faster capture

### Advanced Features
- **Cross-database relationships**: Link projects to people
- **Automated follow-up reminders**: Based on People database
- **Project milestone tracking**: Progress indicators
- **Idea connection detection**: Related concept identification
- **Natural language queries**: Ask questions of your data

## Implementation Phases

### Phase 1: Core Ingestion (MVP)
- Slack capture setup
- Basic N8N workflow
- Ollama classification
- Notion database creation and writing
- Simple confirmation replies

### Phase 2: Audit and Quality
- Inbox Log implementation
- Confidence threshold handling
- Error correction workflow
- Classification prompt refinement

### Phase 3: Surfacing
- Daily digest automation
- Weekly review automation
- Prompt optimization for summaries
- Delivery timing configuration

### Phase 4: Polish and Reliability
- Error handling improvements
- Performance optimization
- Backup and recovery procedures
- Documentation and runbooks

This requirements document provides the complete foundation for implementing Nate's second brain system using your preferred self-hosted technology stack.