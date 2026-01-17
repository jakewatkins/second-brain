# Classification Prompts for Second Brain

This document contains the AI prompts used for classifying and processing messages in the Second Brain system.

## Primary Classification Prompt

Used in: **Ollama - Classify Message** node (HTTP Request)

### Prompt Template

```
You are a message classifier for a personal knowledge management system. Classify the following message into one of four categories: people, projects, ideas, or admin.

Message: {{message_text}}

Extract relevant details and return ONLY valid JSON in this exact format:
{
  "category": "people|projects|ideas|admin",
  "confidence": 0.85,
  "name": "extracted title or name",
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
- Return ONLY the JSON, no additional text or markdown formatting
```

### Category Definitions

#### People
**Trigger words:** "met", "talked to", "call", "email", "follow up with", names, "contact"

**Examples:**
- "Met Sarah at the conference - she works on platform engineering at Acme"
- "Need to follow up with John about the Q3 project proposal"
- "Jane mentioned she's interested in DevOps automation tools"

**Expected extraction:**
- **name**: Person's name
- **details**: Context about relationship, what to remember
- **next_action**: null

#### Projects
**Trigger words:** "need to", "working on", "build", "implement", "refactor", "fix", "deploy"

**Examples:**
- "Refactor the authentication module to support OAuth2 and add unit tests"
- "Build a CI/CD pipeline for the new microservice architecture"
- "Fix the memory leak in the payment processing service"

**Expected extraction:**
- **name**: Project title
- **details**: Project scope and context
- **next_action**: Specific executable first step

#### Ideas
**Trigger words:** "what if", "idea", "concept", "thinking about", "could we", "interesting"

**Examples:**
- "What if we used event sourcing for the audit log? Would give us complete history replay"
- "Interesting concept: canary deployments at the database migration level"
- "Could we apply chaos engineering principles to our testing strategy?"

**Expected extraction:**
- **name**: Idea title/one-liner
- **details**: Full thought and reasoning
- **next_action**: null

#### Admin
**Trigger words:** "schedule", "appointment", "renew", "pay", "deadline", "register", "submit"

**Examples:**
- "Schedule dentist appointment for next Tuesday"
- "Renew car registration by end of month"
- "Submit expense report for Q4 travel"

**Expected extraction:**
- **name**: Task name
- **details**: Additional context
- **next_action**: Specific action to complete task

## Confidence Thresholds

### High Confidence (≥ 0.7)
- Clear category indicators present
- Unambiguous message intent
- → **Action**: Auto-file to database

### Medium Confidence (0.5 - 0.69)
- Some ambiguity in categorization
- Could fit multiple categories
- → **Action**: File but flag for review

### Low Confidence (< 0.5)
- Unclear message intent
- Gibberish or very short message
- → **Action**: Hold for manual review

## Prompt Optimization Tips

### Improving Accuracy

1. **Add examples** to the prompt:
   ```
   Example People: "Met John Smith, CTO at TechCorp"
   Example Project: "Build authentication service with OAuth"
   Example Idea: "What if we used GraphQL instead of REST"
   Example Admin: "Schedule dentist appointment"
   ```

2. **Emphasize JSON-only output**:
   ```
   CRITICAL: Return ONLY the JSON object. No markdown, no code blocks, no explanation.
   ```

3. **Specify confidence guidelines**:
   ```
   Confidence scoring:
   - 0.9-1.0: Obvious category with clear indicators
   - 0.7-0.89: Clear category, minor ambiguity
   - 0.5-0.69: Ambiguous, could be multiple categories
   - 0-0.49: Unclear, needs human review
   ```

### Reducing Latency

1. **Add response time hint**:
   ```
   Respond quickly with classification. Aim for sub-5-second response.
   ```

2. **Limit elaboration**:
   ```
   Keep 'details' field under 200 characters. Summarize concisely.
   ```

3. **Use smaller models** for faster inference:
   - `llama3.2:3b` (faster, good accuracy)
   - `phi3:mini` (fastest, decent accuracy)

## Testing Classification Accuracy

### Test Message Set

Save this to `tests/test-messages.json` and run validation:

```json
{
  "people": [
    "Met Emily Chen at DevOps Days - she's a platform engineer at CloudCorp, interested in Kubernetes",
    "Need to follow up with David about the Q2 infrastructure roadmap",
    "Sarah mentioned she's looking for good resources on GitOps practices"
  ],
  "projects": [
    "Implement feature flags in the frontend application using LaunchDarkly",
    "Migrate database from PostgreSQL to distributed Aurora setup",
    "Build monitoring dashboard for microservices health metrics"
  ],
  "ideas": [
    "What if we applied chaos engineering to test our disaster recovery procedures?",
    "Concept: Use AI to automatically categorize and prioritize tech debt",
    "Interesting idea: event-driven architecture for the entire platform"
  ],
  "admin": [
    "Schedule annual security audit for compliance requirements",
    "Renew SSL certificates before they expire next month",
    "Submit budget proposal for Q2 infrastructure spend"
  ]
}
```

### Validation Script

```bash
#!/bin/bash
# Test classification accuracy

TOTAL=0
CORRECT=0

for category in people projects ideas admin; do
  echo "Testing $category messages..."
  # Send test messages and check classification
  # Compare actual vs expected category
  # Increment TOTAL and CORRECT counters
done

ACCURACY=$((CORRECT * 100 / TOTAL))
echo "Classification Accuracy: ${ACCURACY}%"

# Target: > 85% accuracy
```

## Version History

| Version | Date | Changes | Model |
|---------|------|---------|-------|
| 1.0 | 2026-01-16 | Initial prompt | llama3.2:3b |
| | | Added JSON format constraint | |
| | | Set confidence threshold at 0.7 | |

## Prompt Engineering Resources

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [OpenAI Best Practices](https://platform.openai.com/docs/guides/prompt-engineering)

---

**Note**: Prompts should be version controlled and tested before production deployment. Track accuracy metrics and iterate based on real-world performance.
