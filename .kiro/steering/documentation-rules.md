---
inclusion: always
---

# Documentation Rules

## Core Principle
**Create MINIMAL, ESSENTIAL, COMPREHENSIVE documentation only.**

## Rules
1. ❌ Do NOT create multiple small documents for the same topic
2. ✅ Create ONE comprehensive document that covers everything
3. ❌ Do NOT create separate "analysis", "comparison", "explanation" files
4. ✅ Update existing documents instead of creating new ones
5. ✅ Only create NEW documents when absolutely necessary

## When to Create Documents
- Core user-facing guides (README, installation, usage)
- Critical reference documents (troubleshooting, configuration)
- Essential technical documentation (API, architecture)

## When NOT to Create Documents
- ❌ Analysis documents (put in comments or existing docs)
- ❌ Comparison documents (merge into main doc)
- ❌ Explanation documents (add to relevant doc)
- ❌ Multiple versions of the same guide
- ❌ Temporary notes or summaries

## Example
**BAD:**
- `性能分析-资源消耗.md`
- `脚本工作原理说明.md`
- `修复说明-auto_report对比.md`
- `CONTEXT_TRANSFER_RESPONSE.md`

**GOOD:**
- `README.md` (includes overview and quick start)
- `INSTALLATION.md` (comprehensive installation guide)
- `TROUBLESHOOTING.md` (all common issues)

## Action
When user asks for information:
1. Check if existing document can be updated
2. Only create new document if truly necessary
3. Keep documents comprehensive but concise
