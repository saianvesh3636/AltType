# Skills Maintenance Guide

## Overview

This guide explains how to maintain and update the Claude Skills system for theTypeAlternative.

## When to Update Skills

### 1. Module Changes
**Update skill when**:
- Adding new public APIs or interfaces
- Changing core algorithms or patterns
- Refactoring major components
- Adding significant new features

**Example**: If you add a new speech engine to SpeechKit, update `speechkit-skill/SKILL.md` with the new engine details.

### 2. Architecture Changes
**Update skill when**:
- Modifying module dependencies
- Changing state management patterns
- Refactoring data flow
- Adding new modules

**Example**: If you create a new module, create a new skill for it.

### 3. Best Practice Updates
**Update skill when**:
- Discovering new anti-patterns
- Establishing new coding standards
- Improving performance patterns
- Updating Swift version requirements

**Example**: When migrating to Swift 7, update `development-standards-skill` with new concurrency patterns.

## Skills vs CLAUDE.md vs Documentation

### Use Skills For:
- ✅ Module-specific implementation details
- ✅ Code patterns and examples
- ✅ API usage and integration
- ✅ Troubleshooting specific modules
- ✅ Technical deep-dives

### Use CLAUDE.md For:
- ✅ High-level project vision
- ✅ Current phase and status
- ✅ Development workflows
- ✅ Cross-cutting concerns
- ✅ Project-wide conventions

### Use `docs/` For:
- ✅ Detailed design documents
- ✅ Architecture diagrams
- ✅ Historical context and decisions
- ✅ Performance benchmarks
- ✅ In-depth technical specifications

## Skill Update Process

### 1. Identify Scope
Determine which skill(s) need updating based on the change.

### 2. Update Main SKILL.md
Edit the core `SKILL.md` file with:
- Updated code examples
- New patterns or APIs
- Modified best practices
- Changed integrations

### 3. Update Related Skills
If the change affects integration with other modules, update those skills too.

**Example**: Updating SpeechKit's engine API? Update both:
- `speechkit-skill/SKILL.md`
- `app-architecture-skill/SKILL.md` (module graph section)

### 4. Test Skill Triggering
Verify the skill triggers correctly by asking Claude questions that should activate it:

```bash
# Test speechkit-skill triggers
"How does WhisperKit integration work?"
"What are the available speech engines?"

# Test hotkeykit-skill triggers
"How does anti-bypass work?"
"What are the tier restrictions?"
```

### 5. Update CLAUDE.md Skills List
If you add/remove/rename a skill, update the skills list in `CLAUDE.md`.

## Skill Structure

### Required Elements

Every skill MUST have:

```markdown
---
name: skillname-skill
description: Brief description of what this skill covers and when to use it. Include trigger keywords.
---

# Skill Title

## Overview
Brief overview of the module/system

## Key Concepts
Main concepts and patterns

## Code Examples
Practical code examples

## Integration
How this integrates with other modules

## Critical Rules & Best Practices
Do's and Don'ts

## When to Use This Skill
When to reference this skill

## Related Skills
Links to related skills
```

### Recommended Elements

Optional but valuable:

- **Common Patterns**: Frequently used code patterns
- **Troubleshooting**: Common issues and solutions
- **Testing Strategies**: How to test this module
- **Performance Considerations**: Optimization tips

### Resource Files

Skills can include additional files:

```
skillname-skill/
├── SKILL.md (required)
├── ADVANCED_PATTERNS.md (optional - loaded as needed)
├── MIGRATION_GUIDE.md (optional - for breaking changes)
└── examples/
    ├── basic_usage.swift
    └── advanced_usage.swift
```

## Skill Naming Conventions

### Skill Names
- Format: `modulename-skill`
- Lowercase with hyphens
- Match module name when possible
- Example: `speechkit-skill`, `hotkeykit-skill`

### Description Format
```
[What it does]. Use when working with [keywords]. Covers [key components].
```

**Example**:
```
description: Smart energy-efficient hotkey management system. Use when working with hotkey detection, event taps, keyboard monitoring, or energy optimization. Covers state management, emergency activation patterns, and universal hotkey support.
```

**Trigger Keywords**: Include common search terms users might use:
- Module name (e.g., "hotkeykit", "speechkit")
- Feature names (e.g., "text insertion", "speech recognition")
- Technical terms (e.g., "event tap", "accessibility API")
- Problem domains (e.g., "battery optimization", "anti-bypass")

## Archiving Outdated Information

### When to Archive
- Implementation has significantly changed
- Pattern is no longer recommended
- Module has been refactored or removed

### How to Archive
1. Create `skill/ARCHIVED.md` with outdated info
2. Add timestamp and reason for archiving
3. Update main `SKILL.md` with current approach
4. Reference archive for historical context if needed

**Example**:
```markdown
# ARCHIVED.md

**Archived**: 2024-12-12
**Reason**: UsageGuardian replaced complex validation loops with simple entry guards

## Old Approach (No Longer Used)

[Old implementation details...]
```

## Quality Checklist

Before committing skill updates:

- [ ] All code examples are tested and working
- [ ] Trigger keywords are comprehensive
- [ ] Related skills are cross-referenced
- [ ] Critical rules are clearly stated
- [ ] Integration patterns are documented
- [ ] CLAUDE.md skills list is updated (if needed)

## Common Maintenance Patterns

### Adding a New Module

1. Create new skill directory: `.claude/skills/newmodule-skill/`
2. Create `SKILL.md` with all required sections
3. Update CLAUDE.md skills list
4. Cross-reference in related skills

### Deprecating a Pattern

1. Add ❌ marker to deprecated pattern
2. Show ✅ recommended alternative
3. Explain why change was made
4. Update related skills with new pattern

### Major Refactoring

1. Create `MIGRATION_GUIDE.md` in skill directory
2. Document breaking changes
3. Provide migration examples
4. Update all affected skills
5. Archive old approach if significant

## Skill Ownership

Each skill should have clear ownership:

| Skill Category | Owner |
|----------------|-------|
| Core Technical | Module maintainer |
| Subscription & Anti-Bypass | Monetization team lead |
| UI & UX | UI/UX developer |
| Development & System | Tech lead |

When making changes to a module, the module owner is responsible for updating the corresponding skill.

## Testing Skills

### Manual Testing

Ask Claude questions that should trigger each skill:

```bash
# Test hotkeykit-skill
"How does the smart dormant mode work?"
"Why is my hotkey not responding after inactivity?"

# Test speechkit-skill
"How do I implement StoreKit 2 purchases?"
"What's the best practice for transaction validation?"

# Test hotkeykit-skill
"How does anti-bypass tracking work?"
"What happens when a free user hits their limit?"
```

### Verification

After updates, verify:
- [ ] Skill loads with appropriate queries
- [ ] Code examples are accurate
- [ ] Cross-references work correctly
- [ ] Trigger keywords capture common queries

## Version Control

Skills are version-controlled with the codebase:

- Commit skill updates with related code changes
- Include skill updates in PR descriptions
- Review skills during code review
- Tag major skill overhauls in release notes

**Commit Message Format**:
```
feat(speechkit): Add new WhisperKit model size

- Add large-v3 model support
- Update speechkit-skill with new model details
- Add download size and performance metrics
```

## Questions?

For questions about skills maintenance:
1. Check this guide
2. Review existing skills for patterns
3. Consult Claude Skills documentation: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Related Documentation

- Claude Skills Overview: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Best Practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- CLAUDE.md: Project-level guidance
