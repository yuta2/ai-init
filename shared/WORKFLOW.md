# Development Workflow

任何實作工作都遵循：

```text
Understand
↓
Inspect
↓
Frame
↓
Design
↓
Implement
↓
Run
↓
Test
↓
Observe
↓
Fix
↓
Regression Check
↓
Deliver
```

禁止：

```text
Read request
↓
Start coding immediately
```

---

## 1. Understand

先確認真正任務：

- 使用者想達成什麼？
- 目前出了什麼問題？
- 這是 bug、feature、architecture 還是 UX 問題？
- 哪些條件是硬限制？
- 哪些只是使用者目前想到的方法？

不要急著把自然語言直接翻譯成 Code。

---

## 2. Inspect Existing System

寫 Code 前先探索現有專案。

至少理解：

- repository structure
- architecture
- coding conventions
- naming conventions
- existing components
- utilities
- state management
- data flow
- error handling
- tests
- build / lint commands

先找：

> 系統是不是已經有解法？

優先延續既有模式。

避免同一專案出現第二套做同樣事情的方法。

---

## 3. Frame the Problem

在動手前先用一句話定義：

> 真正要解決的問題是什麼？

接著判斷：

- Root cause
- Symptom
- Constraint
- Desired outcome

修 Bug 時不要只修表面症狀。

問：

> 哪一個 invariant 被破壞？

---

## 4. Design the Minimum Sufficient Solution

提出能完整解決問題的最小方案。

避免：

- speculative architecture
- premature optimization
- 不必要 service
- 不必要 abstraction
- 不必要 dependency

如果修改現有邏輯就能解決，不要建立新平台。

---

## 5. Define Acceptance Criteria

在實作前知道什麼叫做完成。

Acceptance criteria 應包含：

- 正常流程
- 邊界條件
- 失敗條件
- 恢復方式
- 是否破壞既有行為

---

## 6. Implement

實作時：

- 遵循既有結構
- 保持修改範圍最小
- 避免 unrelated refactor
- 避免偷偷改變既有行為
- 保持 interface 清楚
- 優先可讀性

不要同時重構整個系統，除非這是必要條件。

---

## 7. Run

能實際執行，就不要只閱讀 Code。

依專案能力執行：

- build
- compile
- run
- lint
- type check
- migration
- relevant command

程式碼「看起來對」不是驗證。

---

## 8. Test

至少思考：

### Happy Path
正常使用是否成功？

### Empty State
沒有資料時怎麼辦？

### Edge Cases
極端輸入怎麼辦？

### Failure
API fail、timeout、permission denied 怎麼辦？

### Duplicate
重複點擊或 retry 怎麼辦？

### State
refresh / restart 後怎麼辦？

### Concurrency
兩個操作同時發生怎麼辦？

### Regression
既有功能有沒有壞？

---

## 9. Observe

不要只看 command exit code。

確認實際結果：

- UI 是否正確？
- File 是否產生？
- Database 是否真的變更？
- API output 是否合理？
- log 是否出現異常？
- state 是否符合預期？

---

## 10. Fix Root Cause

如果驗證失敗：

不要只 patch symptom。

重新判斷：

- assumption 是否錯？
- state 是否不完整？
- interface 是否不清楚？
- lifecycle 是否缺一段？
- architecture 是否造成問題？

修到真正原因。

---

## 11. Regression Check

任何修正都可能破壞其他地方。

完成後重新檢查：

- 原功能
- 相鄰功能
- 共用 component
- shared utility
- API contract
- data model

---

## 12. Deliver

最後才算完成。

交付時說清楚：

- 做了什麼
- 重要變更
- 驗證結果
- 必要的限制或風險

不要只報告：

> Code 已修改。

而是確認：

> 問題已被解決。
