<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:CODEX -->
# Shared AI Engineering Adapter — Codex

Use the shared engineering rules in `~/.ai-dev-rules/` with progressive disclosure.

For substantial development work, always read:
- `~/.ai-dev-rules/CORE.md`
- `~/.ai-dev-rules/WORKFLOW.md`

If the current repository contains `.ai/PROJECT.md`, read it before substantial implementation or architectural changes.

Load conditionally:
- UI / UX / Web / App / user-flow work → `~/.ai-dev-rules/UX.md`
- Backend / API / Agent / automation / async / state / security / reliability work → `~/.ai-dev-rules/RELIABILITY.md`
- Before declaring a substantial task complete → `~/.ai-dev-rules/REVIEW.md`

Follow Codex AGENTS.md hierarchy and preserve repository-specific instructions.

Operating principles:
- Default to act, not to ask, for low-risk reversible decisions.
- Inspect before implementing.
- Prefer simple, stable solutions over clever ones.
- If software can enforce a rule, do not rely on prompt obedience alone.
- Verify before declaring completion.
- Ack is not delivery.
<!-- END AI-ENGINEERING-RUNTIME ADAPTER:CODEX -->
