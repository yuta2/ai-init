# Product & UX Principles

UI 的目的不是漂亮。

UI 的目的首先是：

> 降低使用者完成事情的認知與操作成本。

每一個畫面都應讓使用者自然知道：

- 我在哪裡？
- 現在發生什麼？
- 我能做什麼？
- 下一步是什麼？
- 哪些事情完成了？
- 哪些事情還在處理？
- 出錯時怎麼辦？

---

## 1. Reduce Waiting

對任何等待都問：

> 這個等待真的必要嗎？

考慮：

- parallel requests
- caching
- lazy loading
- optimistic UI
- streaming
- incremental rendering
- background execution
- preload
- local state
- avoiding redundant API calls

不要用漂亮 spinner 掩蓋可以消除的 latency。

---

## 2. Reduce Interaction Cost

避免：

- 多餘 modal
- 多餘 confirmation
- 多餘 step
- 多餘選項
- 多餘設定
- 重複輸入
- 讓使用者理解內部架構

如果系統可以可靠推導：

→ 自動完成。

---

## 3. Sensible Defaults

好的 Default 可以消除大量 UI。

預設值應：

- 符合最常見情況
- 安全
- 可修改
- 容易理解

不要用：

> 請選擇

作為所有欄位的預設狀態。

---

## 4. Preserve User State

不要讓使用者因為：

- refresh
- back
- navigation
- temporary disconnect
- reopen application

而失去工作。

必要時使用：

- autosave
- draft
- checkpoint
- local persistence
- server state
- undo
- restore

---

## 5. Design Empty States

Empty state 不只是：

> 沒有資料。

應告訴使用者：

- 為什麼沒有
- 可以做什麼
- 如何開始

Empty state 是 onboarding 的一部分。

---

## 6. Prevent Errors

先防止，再報錯。

例如：

不要讓使用者輸入不可能成立的值後才報錯。

使用：

- constraints
- previews
- validation
- dependency checks
- conflict detection
- disabled impossible actions

---

## 7. Actionable Errors

錯誤訊息回答：

1. 發生什麼？
2. 為什麼？
3. 有什麼影響？
4. 下一步怎麼辦？

禁止只有：

- Failed
- Invalid
- Something went wrong
- Unknown error

如果系統可以自動恢復，就不要把處理責任丟給使用者。

---

## 8. Progressive Disclosure

不要一次展示所有功能。

先呈現最重要操作。

進階功能在需要時再出現。

使用者不應因為「可能有一天會用到」而承受現在的複雜度。

---

## 9. Don't Expose Internal Concepts

不要逼使用者理解：

- queue
- worker
- shard
- vector database
- internal ID
- schema
- retry policy

除非這本身就是產品需求。

產品介面應描述：

> 使用者世界。

不是：

> 系統內部世界。

---

## 10. Clear Feedback

操作後必須讓使用者知道結果。

但是 Feedback 不代表每一步都跳通知。

好的回饋可能只是：

- 狀態自然改變
- 按鈕更新
- row 更新
- progress 顯示
- undo 出現

Success toast 不應成為唯一回饋方式。

---

## 11. Delight

功能完成後問：

> 能不能用一個低成本細節，讓體驗明顯更好？

例如：

- 記住上次設定
- 自動恢復
- copy button
- keyboard shortcut
- smart default
- instant validation
- preview
- undo
- conflict detection

Delight ≠ animation。

Delight 是：

> 使用者還沒開口，系統已經想到。
