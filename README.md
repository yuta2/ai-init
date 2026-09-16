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

拒絕修改檔案的情況（都不會動到檔案，並回報非零 exit code）：

- markers 數量不對稱，或出現多組重複 block
- 目標檔案或其所在目錄不可寫
- 寫入中途失敗（磁碟滿、檔案大小限制）
- adapter block 檔案不存在或是空的

`ai-init --status` 會把壞掉的 block 標成 `MALFORMED`。

## marker 比對規則

- 比對是 **byte 精確**的（awk 一律跑在 `LC_ALL=C`）。在 UTF-8 locale 下 awk 的字串比較是
  collation 比對，前面加個 BOM 或全形空白的行會被當成 marker，結果還會隨 locale 改變。
- 忽略行尾的 CR，所以 CRLF 檔案一樣認得自己的 block，不會重複 merge 出第二個。
- 忽略行首空白，所以被縮排過的 marker 仍對得上，不會變成看不見的孤兒 block。
- **fenced code block 裡的 marker 一律忽略**。文件裡示範 managed block 長什麼樣子的
  程式碼區塊不會被刪掉，該檔案也照樣能正常 merge 真正的 block。
  支援 ``` 與 ~~~、縮排、巢狀，關閉的 fence 必須同字元、不短於開啟的、且不帶 info string。

## 寫入方式

檔案不會被就地覆寫。新內容先組在同目錄的暫存檔，再用 rename 換上去，所以寫到一半失敗
（磁碟滿、`RLIMIT_FSIZE`）不會把設定檔截成空的。既有檔案的權限會保留，symlink 也維持是
symlink（寫入它指向的檔案）。

代價是 merge 需要目標檔**所在目錄**可寫。目錄唯讀時會明確失敗，不會退回就地覆寫。

## 測試

```bash
bash test-lib.sh
```

`lib.sh` 會寫進 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 等全域設定檔，
所以 merge / remove / 版本讀取的行為都有對應檢查（97 項）。

測試本身用「種突變到 `lib.sh`，看有沒有測試變紅」的方式驗過。
