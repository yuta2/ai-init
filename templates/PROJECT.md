# Project Context

> 本文件只存放「此專案」的事實、決策與目前狀態。
>
> 不要複製 CORE / WORKFLOW / UX / RELIABILITY 的通用規則到這裡。

---

## 1. Project

**Project Name**

`<project-name>`

**Purpose**

這個系統要解決：

`<problem>`

**Primary Users**

`<users>`

---

## 2. Product Goals

本專案最重要的成果：

1. `<goal>`
2. `<goal>`
3. `<goal>`

---

## 3. Non-Goals

目前刻意不做：

- `<non-goal>`
- `<non-goal>`

避免 AI 因為看到可能性就自行擴張 scope。

---

## 4. Tech Stack

### Frontend
`<framework / language>`

### Backend
`<framework / language>`

### Database
`<database>`

### Infrastructure
`<infra>`

### AI / Models
`<model / agent / RAG stack>`

---

## 5. Architecture

核心架構：

```text
<Component>
   ↓
<Component>
   ↓
<Component>
```

重要模組：

| Module | Responsibility |
|---|---|
| `<module>` | `<responsibility>` |

---

## 6. Repository Structure

```text
src/
├── ...
```

重要目錄：

- `<path>`：`<purpose>`
- `<path>`：`<purpose>`

---

## 7. Existing Patterns

本專案既有慣例：

### State
`<pattern>`

### API
`<pattern>`

### Error Handling
`<pattern>`

### UI Components
`<pattern>`

### Logging
`<pattern>`

### Testing
`<pattern>`

新的實作應優先延續以上模式。

---

## 8. Constraints

必須遵守：

- `<constraint>`
- `<constraint>`

例如：

- 必須離線執行
- 不可使用 SaaS
- Windows Server 2016
- 必須支援 Traditional Chinese
- 不可破壞既有 API

---

## 9. Security Boundaries

敏感資料：

- `<data>`

權限限制：

- `<permission>`

外部不可信資料來源：

- `<source>`

---

## 10. Architecture Decisions

### ADR-001

**Decision**

`<decision>`

**Reason**

`<reason>`

**Alternatives Considered**

`<alternatives>`

**Status**

Accepted / Deprecated / Replaced

---

## 11. Known Issues

目前已知：

### ISSUE-001

`<problem>`

Impact:

`<impact>`

Status:

`Open / Investigating / Deferred`

---

## 12. Current State

目前已完成：

- [ ] `<item>`

正在進行：

- [ ] `<item>`

下一步：

- [ ] `<item>`

---

## 13. Important Context

後續 Agent 必須知道：

- `<fact>`
- `<decision>`
- `<important context>`

只保留未來仍會影響決策的資訊。

不要把每日工作紀錄全部塞進這裡。

---

## 14. Definition of Done

本專案的一個 Feature 只有在以下條件成立時才算完成：

- 實際功能完成
- 已實際執行
- Relevant tests 通過
- Build / lint / type check 通過
- Failure path 已考慮
- 沒有破壞既有功能
- 使用者可以真正取得成果
