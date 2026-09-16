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

## 備份

每次執行動到檔案之前，會把該檔案備份一份到：

```text
.ai/backups/<timestamp>-<pid>/
```

同一次執行只備份一次，所以拿到的是**執行前**的完整狀態，不是 merge 到一半的檔案。
`.ai/backups/.gitignore` 會自動建立，備份不會進版控。

## 版本與過期檢查

每個 project adapter block 內含 `<!-- ai-runtime-version: N -->`。
改過 `adapters/*/PROJECT_BLOCK.md` 並重跑 `install-all.sh` 之後，
在各專案跑 `ai-init --status` 就會標出哪些 block 過期：

```text
  CLAUDE  CLAUDE.md   OUTDATED (v1 installed, v2 available — re-run ai-init)
```

## 錯誤處理

某個 adapter 的 managed block markers 壞掉時，`ai-init`、`install-all.sh`、`uninstall-all.sh`
都會**跳過該 adapter 繼續處理其他的**，最後列出被跳過的項目並以非零 exit code 結束。
`install-all.sh` 即使有 adapter 失敗，仍會裝好共用憲章與 `ai-init` 指令。

拒絕修改檔案的情況：

- markers 數量不對稱，或出現多組重複 block
- markers 出現在 fenced code block 裡（刪掉 block 會連帶吃掉使用者內容）
- 目標檔案不可寫（唯讀檔、唯讀檔案系統）

這三種都不會動到檔案，並回報非零 exit code。`ai-init --status` 會把壞掉的 block 標成 `MALFORMED`。

行尾是 CRLF 的檔案一樣能正確比對 marker，不會重複 merge 出第二個 block。

## 測試

```bash
bash test-lib.sh
```

`lib.sh` 會寫進 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 等全域設定檔，
所以 merge / remove / 版本讀取的行為都有對應檢查。
