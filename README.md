# Second Brain

> An intelligent personal knowledge management system that automatically captures, classifies, and surfaces your thoughts, ideas, and tasks.

## 🧠 What is This?

This project implements a "second brain" system based on [Nate Jones's methodology](https://youtu.be/0TpON5T-Sw4?si=XbWPN1orPOqFuQ3G) - an AI-powered automation that helps you:

- **Capture thoughts instantly** without disrupting your flow
- **Automatically organize** everything into the right buckets  
- **Surface relevant information** when you need it
- **Close mental loops** so your brain can focus on thinking, not remembering

## 🛠 Architecture

This implementation uses a **self-hosted stack** for maximum control and privacy:

```
Slack (SB-Inbox) → N8N → Ollama → Notion Databases
                     ↓
                Daily/Weekly Digests
```

### Technology Stack
- **[Slack](https://slack.com)**: Frictionless capture interface
- **[N8N](https://n8n.io)**: Self-hosted workflow automation 
- **[Ollama](https://ollama.ai)**: Local AI for classification and processing
- **[Notion](https://notion.so)**: Structured storage and knowledge base

## 🎯 Core Concept

### The Problem
Your brain wasn't designed to be a storage system - it was designed to **think**. Every time you force your brain to remember something instead of letting it process new ideas, you pay a cognitive tax that shows up as:

- 💔 Relationships that cool off because you forgot important details
- 📉 Projects that fail in predictable ways you saw coming but forgot to document
- 😰 Constant background anxiety from open loops you can't close

### The Solution
An **active system** that works while you sleep:
- **Classifies** your thoughts automatically
- **Routes** them to the right place without your input
- **Surfaces** relevant information proactively
- **Nudges** you toward your goals and priorities

## 🏗 System Components

### Input Layer
- **Single capture point**: Slack `SB-Inbox` channel
- **5-second rule**: Any thought should take ≤5 seconds to capture
- **Zero decisions**: Just type and send, no organizing required

### Processing Layer  
- **AI Classification**: Ollama automatically categorizes into People, Projects, Ideas, or Admin
- **Confidence Scoring**: Low-confidence items held for review (≥0.6 threshold)
- **Structured Extraction**: Pulls out names, contexts, next actions automatically

### Storage Layer
5 Notion databases with specific schemas:

1. **👥 People**: Contacts, contexts, follow-ups, last touched
2. **📋 Projects**: Status, next actions, notes, progress tracking  
3. **💡 Ideas**: Insights, one-liners, elaboration space
4. **📝 Admin**: Tasks, due dates, administrative items
5. **📊 Inbox Log**: Complete audit trail of all processing

### Output Layer
- **Daily Digest**: Morning summary (≤150 words) with top 3 actions
- **Weekly Review**: Sunday reflection (≤250 words) with patterns and planning
- **Error Correction**: Fix classifications via simple Slack replies

## 🚀 Key Features

### ✅ Frictionless Capture
- Single Slack channel for all inputs
- No tagging, folders, or decisions required
- Works on mobile, desktop, anywhere Slack runs

### 🤖 Intelligent Processing
- Automatic classification using local AI
- Confidence-based routing with human fallback
- Extracts actionable next steps from vague inputs

### 🔍 Proactive Surfacing  
- Daily digest delivered to Slack DMs
- Weekly reviews with pattern recognition
- Surfaces relevant information without searching

### 🛡 Trust & Transparency
- Complete audit trail of all processing
- Easy error correction without opening databases
- Confidence scores for all AI decisions
- Graceful failure handling

## 🎛 Implementation Phases

### Phase 1: Core Ingestion (MVP)
- [ ] Set up Slack workspace and SB-Inbox channel
- [ ] Deploy self-hosted N8N instance
- [ ] Configure Ollama with suitable model
- [ ] Create Notion databases with proper schemas
- [ ] Build basic capture → classify → store workflow

### Phase 2: Quality & Reliability
- [ ] Implement Inbox Log audit trail
- [ ] Add confidence threshold handling  
- [ ] Build error correction workflow
- [ ] Tune classification prompts for accuracy

### Phase 3: Intelligence Layer
- [ ] Daily digest automation with smart summaries
- [ ] Weekly review with pattern detection
- [ ] Optimize prompt engineering for consistent output
- [ ] Fine-tune delivery timing and formatting

### Phase 4: Polish & Scale
- [ ] Performance monitoring and optimization
- [ ] Backup and recovery procedures
- [ ] Enhanced error handling and logging
- [ ] Documentation and operational runbooks

## 🧩 Core Principles

This system follows proven engineering principles adapted for personal knowledge management:

1. **Single Reliable Behavior**: Only one capture method, everything else automated
2. **Separation of Concerns**: Memory (Notion) + Compute (N8N/Ollama) + Interface (Slack)  
3. **API-First Prompts**: Structured, predictable AI responses over creative ones
4. **Trust Mechanisms**: Audit trails, confidence scores, easy corrections
5. **Safe Defaults**: When uncertain, ask for clarification rather than guess
6. **Small, Frequent Outputs**: Digestible summaries over overwhelming reports
7. **Next-Action Oriented**: Executable steps, not vague intentions
8. **Route, Don't Organize**: Let AI sort into stable buckets automatically
9. **Minimal Complexity**: Few categories, few fields, fewer decisions
10. **Restart-Friendly**: Easy to resume after breaks without guilt or cleanup

## 📖 Inspiration & Resources

- **Original Video**: [How to Build a Second Brain in 2026](https://youtu.be/0TpON5T-Sw4?si=XbWPN1orPOqFuQ3G) by Nate Jones
- **Detailed Guide**: [Why every system you've tried has failed + grab the 90-minute guide to one that won't](https://natesnewsletter.substack.com/p/grab-the-system-that-closes-open)
- **Core Philosophy**: Building an **active system** that works for you, not a passive storage dump

## 🎯 Success Metrics

### System Health
- **Classification Accuracy**: >85% of items filed correctly
- **Response Time**: <30 seconds from capture to storage
- **Uptime**: >95% availability for core workflows
- **Error Rate**: <5% of ingestions fail

### Personal Impact
- **Cognitive Relief**: Reduced mental overhead from open loops
- **Consistent Usage**: Daily posting to SB-Inbox becomes habitual  
- **Trust**: Low correction rate, continued engagement
- **Compound Value**: Ideas build on each other over time

## 🔮 Future Enhancements

- **Voice Capture**: Audio message processing via speech-to-text
- **Email Integration**: Forward emails directly to second brain
- **Calendar Sync**: Meeting prep using People database context
- **Cross-References**: Automatic linking between related items
- **Mobile Shortcuts**: iOS/Android shortcuts for instant capture
- **Natural Language Queries**: Ask questions of your accumulated knowledge

## 📂 Repository Structure

```
├── README.md              # This file
├── requirements.md        # Comprehensive technical requirements  
├── video-transcript.md    # Full transcript of Nate's methodology video
├── notes.md              # Project development notes
└── .github/              # Agents, prompts, and automation configs
```

## 🚀 Getting Started

1. **Review Requirements**: Read `requirements.md` for detailed technical specifications
2. **Watch the Video**: [Nate's explanation](https://youtu.be/0TpON5T-Sw4?si=XbWPN1orPOqFuQ3G) of the methodology
3. **Set Up Infrastructure**: Deploy N8N, Ollama, configure Slack workspace
4. **Build Phase 1**: Start with basic capture and classification workflow
5. **Iterate**: Add intelligence layers and polish based on real usage

---

*"For the first time in human history, we have access to systems that do not just passively store information, but actively work on that information while we sleep."* - Nate Jones