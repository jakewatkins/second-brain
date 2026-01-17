# Phase 1: Core Ingestion Workflow

This directory contains all resources needed to implement the core ingestion workflow for Second Brain.

## Directory Structure

```
phase1-ingestion/
├── README.md                          # This file
├── workflows/                         # N8N workflow definitions
│   └── slack-inbox-processor.json    # Main ingestion workflow
├── scripts/                           # Helper scripts
│   ├── test-ollama.sh                # Test Ollama classification
│   ├── verify-notion.sh              # Verify Notion database setup
│   ├── send-test-messages.sh         # Send test messages to Slack
│   └── check-workflow-health.sh      # Monitor workflow execution
├── config/                            # Configuration templates
│   ├── notion-database-ids.txt       # Database ID reference
│   └── classification-prompts.md     # AI prompt templates
└── tests/                             # Test message examples
    └── test-messages.json            # Sample messages for each category
```

## Prerequisites

Before implementing Phase 1, ensure Phase 0 is complete:

- ✅ Docker infrastructure running (N8N + Ollama)
- ✅ Slack workspace with SB-Inbox channel configured
- ✅ Notion databases created (People, Projects, Ideas, Admin, Inbox Log)
- ✅ API credentials secured in `.env` file

## Quick Start

### 1. Verify Infrastructure
```bash
cd scripts
./check-workflow-health.sh
```

### 2. Test Ollama Classification
```bash
./scripts/test-ollama.sh "Call John about the website project"
```

### 3. Import N8N Workflow
1. Open N8N: http://localhost:5678
2. Click "Import from File"
3. Select `workflows/slack-inbox-processor.json`
4. Configure credentials (see Phase1-deployment.plan.md Step 2)

### 4. Run End-to-End Tests
```bash
# Send test messages to validate each category
./tests/send-test-messages.sh
```

## Key Files

### Workflows
- **slack-inbox-processor.json**: Complete N8N workflow for capturing Slack messages, classifying with Ollama, and filing to Notion

### Scripts
- **test-ollama.sh**: Test Ollama API and classification prompts
- **verify-notion.sh**: Verify Notion databases are properly configured
- **send-test-messages.sh**: Post test messages to Slack for validation
- **check-workflow-health.sh**: Monitor N8N workflow execution status

### Configuration
- **notion-database-ids.txt**: Template for documenting Notion database IDs
- **classification-prompts.md**: Prompt engineering templates for AI classification

## Implementation Steps

Follow the detailed plan in `../Phase1-deployment.plan.md`:

1. **Step 1**: Verify infrastructure readiness
2. **Step 2**: Configure N8N credentials
3. **Step 3**: Create core ingestion workflow (import from `workflows/`)
4. **Step 4**: Add Notion database writers
5. **Step 5**: Add audit trail (Inbox Log)
6. **Step 6**: Add Slack confirmation replies
7. **Step 7**: Add error handling
8. **Step 8**: Testing and validation
9. **Step 9**: Workflow optimization
10. **Step 10**: Activate and monitor

## Testing

### Manual Testing
1. Post message to Slack #sb-inbox
2. Check N8N Executions tab
3. Verify entry created in Notion
4. Confirm Slack reply posted

### Automated Testing
```bash
# Run full test suite
./scripts/test-all.sh

# Test specific category
./scripts/send-test-messages.sh people
```

## Monitoring

### Check Workflow Health
```bash
# View N8N logs
docker logs -f second-brain-n8n

# Check recent executions
./scripts/check-workflow-health.sh
```

### Performance Metrics (DORA)
- **Lead Time**: < 30 seconds (Slack message → Notion entry)
- **Success Rate**: > 95% of messages classified correctly
- **Confidence**: > 85% of messages have confidence ≥ 0.7

## Troubleshooting

See `../Phase1-deployment.plan.md` Section "Troubleshooting Guide" for:
- Slack trigger not firing
- Ollama not responding
- Notion database errors
- Low confidence classifications
- Slack confirmation not posted

## Next Steps

After successful Phase 1 implementation:
- **Phase 2**: Audit and quality improvements
- **Phase 3**: Daily and weekly digest workflows
- **Phase 4**: Deploy to production
- **Phase 5**: Pilot testing with real usage

---

**DevOps Principles Applied:**
- **Automation**: Fully automated capture-to-storage pipeline
- **Measurement**: Execution tracking via N8N logs and Inbox Log database
- **Lean**: Minimal viable workflow delivering immediate value
- **Sharing**: Version-controlled workflows and documentation
