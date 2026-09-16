# AI Engineering Runtime Pack v2

支援 Codex CLI、Claude Code、Pi Agent、DeepSeek Harness。

## 第一次：全域安裝

```bash
bash install-all.sh
```

這會：
- 安裝共用 AI 工程憲章到 `~/.ai-dev-rules/`
- Merge 四套工具各自的全域入口
- 安裝 `ai-init`

## 之後：每個專案只做一次

```bash
cd /path/to/project
ai-init
```

`ai-init` 會自動找 Git repository 根目錄；如果不是 Git repo，就使用目前資料夾。

它會：
- 保留既有 `AGENTS.md`
- 保留既有 `CLAUDE.md`
- 只 merge managed blocks
- 若 `.ai/PROJECT.md` 不存在才建立
- 可以安全重跑

## 常用

```bash
ai-init
ai-init --status
ai-init --remove
ai-init --help
```

`--remove` 只移除 managed project adapters，不刪 `.ai/PROJECT.md`。
