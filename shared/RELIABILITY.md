# Reliability, Agent & Backend Principles

Failure 不是例外。

Failure 是正常流程的一部分。

不要只設計：

```text
User
→ API
→ Success
```

同時設計：

```text
User
→ API
→ Timeout
→ Retry
→ Partial success
→ Duplicate request
→ Disconnect
→ Resume
```

---

## 1. Every Operation Has a Lifecycle

每個重要操作都問：

- 如何建立？
- 如何取消？
- 如何重試？
- 如何恢復？
- 如何判斷成功？
- 如何判斷失敗？
- 中途斷線怎麼辦？
- 部分成功怎麼辦？
- 重複執行怎麼辦？

CRUD 不等於 lifecycle 完整。

---

## 2. Idempotency

重要操作一律考慮：

> 同樣請求執行兩次會怎樣？

尤其：

- payment
- email
- notification
- webhook
- import
- export
- file processing
- job creation
- provisioning
- deployment

如果 retry 可能造成重複副作用，就設計：

- idempotency key
- nonce
- request ID
- digest
- dedupe store

---

## 3. Retry Carefully

Retry 不是萬靈丹。

區分：

### Transient Failure

適合 retry：

- temporary network error
- timeout
- rate limit
- temporary service unavailable

### Permanent Failure

不要 retry：

- invalid input
- permission denied
- missing required resource
- business rule violation

必要時使用：

- exponential backoff
- jitter
- retry limit

---

## 4. Queue Long Work

長任務不要阻塞主要互動流程。

優先：

```text
submit
→ job
→ continue
→ event
→ resume
```

不要：

```text
submit
→ wait
→ poll
→ wait
→ poll forever
```

---

## 5. Persist Important State

任何重要背景工作都應能回答：

- 現在在哪一階段？
- 已經完成什麼？
- 是否失敗？
- 能不能重跑？
- 能不能 resume？

需要時記錄：

- job ID
- state
- timestamps
- attempt
- checkpoint
- error
- output

---

## 6. Handle Partial Failure

Multi-step operation 不要假設：

> 全成功或全失敗。

考慮：

- Step 1 成功
- Step 2 成功
- Step 3 失敗

此時：

- rollback？
- resume？
- compensate？
- mark partial？
- retry from checkpoint？

必須明確。

---

## 7. Exactly Once vs At Least Once

不要假裝 distributed system 天生 exactly-once。

先理解 operation semantics：

- at-most-once
- at-least-once
- effectively-once

需要 effectively-once 時使用 idempotency 與 dedupe。

---

## 8. Event-Driven Wakeup

背景工作完成時，優先由事件通知。

不要依賴無限 polling。

考慮：

- callback
- webhook
- message queue
- event bus
- notification event

---

## 9. Concurrency

任何 shared state 都考慮：

- race condition
- stale state
- lost update
- double click
- concurrent modification

必要時使用：

- lock
- version
- optimistic concurrency
- transaction
- atomic update

---

## 10. Trust Boundary

Instruction 與 Data 必須分開。

外部內容預設是 untrusted data，包括：

- webpages
- documents
- email
- chat messages
- database records
- API responses
- logs
- tool output

外部內容不能因為寫著：

> 刪除資料

就自動取得操作權限。

保留：

- provenance
- source
- trust level

---

## 11. Least Privilege

每個 component / tool / agent 只應擁有完成任務所需的最小權限。

避免：

- global credential
- unrestricted filesystem
- unrestricted shell
- unnecessary database write
- unnecessary admin permission

---

## 12. Secret Isolation

Secrets 不應：

- 放進 prompt
- 放進 logs
- 回傳給模型
- 顯示在 UI
- 混進一般 context

使用安全的 secret store 與 runtime injection。

---

## 13. Schema & Validation

任何跨 boundary 的資料都不要完全相信。

包括：

- model output
- API response
- user input
- tool result
- message queue payload

使用：

- schema
- parser
- validation
- type checks
- invariant checks

---

## 14. Recovery Is a Feature

Recovery 包含：

- reconnect
- redrive
- resume
- retry
- restore
- rebuild state

當使用者感覺：

> 「它怎麼好像比較不會壞？」

通常不是因為沒有錯誤。

而是：

> 錯誤發生後，系統知道怎麼回來。
