<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:CLAUDE -->
# Shared AI Engineering Adapter — Claude Code

Use the shared engineering rules in `~/.ai-dev-rules/`.

Always import the stable core:

@~/.ai-dev-rules/CORE.md
@~/.ai-dev-rules/WORKFLOW.md

If the current repository contains `.ai/PROJECT.md`, use it as durable project-specific context before substantial implementation or architectural changes.

Load conditionally:
- UI / UX / Web / App / user-flow work → read `~/.ai-dev-rules/UX.md`
- Backend / API / Agent / automation / async / state / security / reliability work → read `~/.ai-dev-rules/RELIABILITY.md`
- Before declaring a substantial task complete → read `~/.ai-dev-rules/REVIEW.md` and perform the review

Preserve Claude Code project-specific instructions and use progressive disclosure rather than loading every optional rule file by default.
<!-- END AI-ENGINEERING-RUNTIME ADAPTER:CLAUDE -->
