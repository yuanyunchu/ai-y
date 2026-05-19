---
name: integration-test
description: Verify the OpenSpec workflow is complete and consistent from Explore to Archive. Use to validate that a change has all required artifacts and the process is closed-loop.
---

# Integration Test — 流程联调测试

## 这是什么

联调测试 = 检查一次完整的开发流程是否走通了。

就像装修完后检查：水电通了吗？门窗能关吗？流程能不能跑通？

## 什么时候用

- 完成一个 change 的开发后（Apply 结束）
- 准备 archive 前，想确认一下流程完整性
- 发现流程卡住了，不知道哪里断了
- 刚开始学，想验证自己的操作对不对

## 测试内容

我会帮你检查 4 个方面：

### 1. 文件完整性检查

一个标准的 change 应该有这些文件：

```
openspec/changes/<change-name>/
├── .openspec.yaml          ← 变更元数据（必须有）
├── proposal.md             ← 需求提案（Explore 产出）
├── design.md               ← 设计方案（Propose 产出）
├── tasks.md                ← 任务列表（Apply 产出）
└── specs/                  ← 规格说明（可选）
    └── <capability>/
        └── spec.md
```

检查项：
- [ ] `.openspec.yaml` 存在且格式正确
- [ ] `proposal.md` 存在且包含 "What & Why"
- [ ] `design.md` 存在且包含 "How"
- [ ] `tasks.md` 存在且任务有勾选状态

### 2. 上下文传递检查

检查下游是否读了上游的产出：

- [ ] `design.md` 是否引用了 `proposal.md` 里的需求？
- [ ] `tasks.md` 是否和 `design.md` 的设计一致？
- [ ] `specs/` 里的规格是否和 `design.md` 匹配？

### 3. Skills 引用检查

检查 skills 之间是否连贯：

- [ ] 从 Explore → Propose → Apply → Archive 的路径是否通顺
- [ ] 被引用的 skill 文件是否存在（如 archive 引用 sync-specs）
- [ ] 工具名是否和环境匹配（如 todowrite、question）

### 4. Git 流程检查

- [ ] 提交历史是否规范（feat/fix/refactor 前缀）
- [ ] 是否有未提交的修改
- [ ] 是否和远程同步

## 怎么用

直接说：

> "帮我联调一下 `add-points-deduction` 这个 change"

或者：

> "跑一下联调测试"

我会自动检查，然后给你报告。

## 输出示例

```
## 联调测试报告：add-points-deduction

### 1. 文件完整性 ✅
- [x] .openspec.yaml — 存在
- [x] proposal.md — 存在，包含需求描述
- [x] design.md — 存在，包含架构设计
- [x] tasks.md — 存在，3/5 任务已完成

### 2. 上下文传递 ⚠️
- [x] design.md 引用了 proposal.md 的需求
- [x] tasks.md 和 design.md 一致
- [ ] specs/points-deduction/spec.md — 缺失（可选）

### 3. Skills 引用 ✅
- [x] openspec-explore → openspec-propose → openspec-apply-change → openspec-archive-change
- [x] openspec-sync-specs 存在（被 archive 引用）
- [x] code-review 存在
- [x] user-review-gate 存在
- [x] git-sync-guard 存在

### 4. Git 流程 ✅
- [x] 工作区干净，无未提交修改
- [x] 与远程同步

---

**结论：流程基本完整，可以进入 Archive 阶段**
**建议：补充 specs/points-deduction/spec.md 会更完整**
```

## 如果发现问题的处理

| 问题 | 怎么办 |
|------|--------|
| 缺少文件 | 告诉你是哪个阶段漏了，建议补做 |
| 上下文不一致 | 指出矛盾点，建议修改 |
| Skills 缺失 | 列出缺失的 skill，建议创建 |
| Git 未同步 | 提示先 pull/push |

## 完整使用场景

```
你: "帮我联调一下 add-points-deduction"

AI: [检查所有文件]

## 联调测试报告...

你: "看起来可以了，帮我归档"

AI: [进入 openspec-archive-change 流程]
```

## 规则

- 联调不替代 user-review-gate，两者都要过
- 先联调（流程完整性）→ 再归档（收尾）
- 联调发现问题时，修完再跑一次
