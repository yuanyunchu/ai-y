# AI 驱动研发全流程规范 v1.0

> **适用范围**：所有使用 AI 辅助的软件开发项目
> **目标**：让 AI 产出可预测、可审查、可回滚

---

## 一、核心理念

### 1.1 人机分工

| 人类做 | AI 做 |
|-------|-------|
| 决定做什么（需求） | 调研怎么做（方案对比） |
| 判断对不对（审查） | 写代码、写文档、写测试 |
| 把控质量（把关） | 自检、联调、归档 |
| 承担责任（决策） | 执行、生成、整理 |

### 1.2 三条铁律

1. **AI 产出必审查** — 没有你的通过，不落地
2. **上下文必传递** — 下游必读上游产出，禁止跨环节读原始需求
3. **流程必闭环** — OpenSpec 四阶段（Explore → Propose → Apply → Archive）+ 质量门禁（Review → Test → Commit），每个 change 必须走完

---

## 二、六层研发 × 九阶段全流程映射

| 研发环节 | 阶段 | 推荐模型 | 核心技能 | 产出物 | 质量关卡 |
|---------|------|---------|---------|--------|---------|
| **① 需求与调研** | Explore | Kimi-k2.6 / Claude Sonnet 200k | openspec-explore | proposal.md + project-context/01-requirement/ | 需求评审 |
| **② 架构与设计** | Propose | DeepSeek-v4-pro / o3 / Claude 3.7 thinking | openspec-propose | design.md + specs/ + project-context/02-design/ | 架构评审 |
| **③ 核心开发（后端）** | Apply（攻坚） | DeepSeek-v4-pro / o3-mini-high | openspec-apply-change + dynamic-test | 核心算法/框架层代码 | Quality Gate L1-L2 |
| **③ 核心开发（前端）** | Apply（攻坚） | DeepSeek-v4-pro / Claude 3.7 Sonnet | openspec-apply-change + dynamic-test | 核心组件/权限/SDK封装 | Quality Gate L1-L2 |
| **④ 标准开发（后端）** | Apply（量产） | Ark-code-latest / GPT-4o / Gemini Flash | openspec-apply-change | CRUD/API/UT 样板代码 | Quality Gate L1 |
| **④ 标准开发（前端）** | Apply（量产） | Ark-code-latest / GPT-4o / Gemini Flash | openspec-apply-change | 列表页/表单页/详情页 样板代码 | Quality Gate L1 |
| **⑤ 测试 Debug** | Apply（收尾） | DeepSeek-v4-flash / GPT-4o-mini | dynamic-test + quality-gate | 修复代码 + 测试用例 | Quality Gate L3-L4 |
| **⑥ 前后端联调** | Verify | DeepSeek-v4-flash / GPT-4o-mini | contract-verify + dev-schema-guard | 联调报告 + Schema 拦截器 | 契约测试 |
| **⑦ 代码评审** | Review | 红蓝对抗（见下表） | code-review | 评审报告 | Critical=0 |
| **⑧ 用户审查** | Review | — | user-review-gate | 通过/修改/重做 | 你的决定 |
| **⑨ 提交归档** | Commit/Archive | — | git-sync-guard + openspec-archive-change | Git commit + Archive | Integration Test |

### 红蓝对抗评审模型匹配

| 开发模型 | 评审模型 | 评审重点 |
|---------|---------|---------|
| DeepSeek-v4-pro | Claude 3.7 / o3-mini | 边界条件、并发安全、异常处理 |
| Kimi-k2.6 | DeepSeek-v4-pro | 逻辑一致性、架构合规性 |
| GPT-4o | Claude 3.5 Sonnet | 代码异味、过度工程 |

---

## 三、完整流程图

```
代码生成
   |
   v
+---------------------------------+
| ④ Quality Gate（AI 自检）       | <- 自动执行
| L1-L4                           |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑤ Code Review（红蓝对抗）       | <- AI 交叉评审
| 产出：Critical/Warning/Suggestion |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑥ User Review Gate（你审查）    | <- 强制人工
| 选项：通过 / 修改 / 重做 / 讨论 |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑦ Git Sync Guard（提交推送）    | <- 流程守卫
| fetch -> commit -> diff -> push |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑧ Contract Verify（联调）       | <- 前后端
| dev-schema-guard + contract-verify |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑨ Integration Test（流程联调）  | <- 闭环验证
| 文件 / 上下文 / Skills / Git     |
+---------------------------------+
   |
   v
+---------------------------------+
| ⑩ Archive（归档）               | <- 收尾
| openspec-archive-change         |
+---------------------------------+
```

---

## 四、分阶段 SOP

### 阶段 ①：Explore（需求调研）

**触发条件**：你有一个新想法，或要修改现有功能

**操作步骤**：
1. 你说："Explore 一下，我想做 XXX"
2. AI 加载 openspec-explore skill
3. AI 读取现有 openspec/changes/ 列表，了解上下文
4. AI 问澄清问题，帮你梳理需求
5. AI 输出思考过程，确认方向
6. 你确认后，AI 生成 proposal.md

**产出物**：
- openspec/changes/<name>/proposal.md
- openspec/changes/<name>/.openspec.yaml

**质量检查**：
- [ ] proposal.md 包含 Why & What
- [ ] 需求范围明确，无歧义
- [ ] 和现有 change 无冲突

---

### 阶段 ②：Propose（架构设计）

**触发条件**：Explore 完成，proposal.md 已确认

**操作步骤**：
1. AI 自动进入 openspec-propose
2. AI 读取 proposal.md 作为输入
3. AI 按依赖顺序生成 artifacts：
   - design.md — 技术方案
   - specs/<capability>/spec.md — 详细规格
   - tasks.md — 任务清单
4. 每个 artifact 生成后，AI 标记进度

**产出物**：
- openspec/changes/<name>/design.md
- openspec/changes/<name>/specs/<capability>/spec.md
- openspec/changes/<name>/tasks.md

**质量检查**：
- [ ] design.md 引用了 proposal.md 的需求
- [ ] tasks.md 和 design.md 一致
- [ ] 技术选型符合 project-context/00-global/architecture-baseline.md

---

### 阶段 ③：Apply（核心开发）

**触发条件**：Propose 完成，tasks.md 已就绪

**操作步骤**：
1. AI 加载 openspec-apply-change + dynamic-test
2. AI 读取 contextFiles：proposal + specs + design + tasks
3. AI 按 tasks.md 逐个实现：
   - 每完成一个 task，标记 [x]
   - 同时生成对应测试代码
4. 遇到设计问题 -> 暂停，建议更新 design.md

**产出物**：
- 业务代码（src/）
- 单元测试（src/test/java/.../unit/）
- 集成测试（src/test/java/.../integration/）

**模型分配**：
- 核心算法/框架层 -> DeepSeek-v4-pro / o3-mini-high
- CRUD/样板代码 -> Ark-code-latest / GPT-4o / Gemini Flash

---

### 阶段 ④：Quality Gate（AI 自检）

**触发条件**：Apply 完成，代码已生成

**自动执行，无需你操作**：

| 层级 | 检查项 | 自动修？ | 失败处理 |
|------|--------|---------|---------|
| L1 基础 | 语法错误、格式、调试代码残留 | 是 | 修完再审 |
| L2 规范 | 命名、API 路径、架构分层 | 否 | 汇报等你 |
| L3 逻辑 | 空值、边界、性能 | 否 | 汇报等你 |
| L4 测试 | 覆盖率、契约符合度 | 否 | 汇报等你 |

**通过标准**：L1 必须全过，L2-L4 允许警告但无 Critical

---

### 阶段 ⑤：Code Review（红蓝对抗）

**触发条件**：Quality Gate 通过

**操作步骤**：
1. AI 识别开发模型（哪个 AI 写的代码）
2. AI 按模型匹配评审模型（见红蓝对抗表）
3. AI 读取变更文件 + 测试 + design.md
4. AI 按 checklist 逐项审查
5. AI 分类问题：Critical / Warning / Suggestion

**通过标准**：Critical = 0

---

### 阶段 ⑥：User Review Gate（你审查）

**触发条件**：Code Review 通过

**你的操作**：
1. AI 展示完整产出：代码摘要 + 关键 diff + 完整内容
2. 你做出决定：

| 指令 | 含义 | AI 动作 |
|------|------|---------|
| 通过 / OK | 没问题，保存 | git add + commit |
| 改下第 X 行 | 小修改 | 修改后重新进入 User Review |
| 不对，重做 | 方向错了 | 废弃当前，回到 Apply 重新来 |
| 为什么... | 不理解 | 解释清楚，等你再决定 |

**规则**：没你的明确通过，不执行任何保存/提交/推送

---

### 阶段 ⑦：Git Sync Guard（提交推送）

**触发条件**：User Review 通过

**强制流程**：

```
git fetch origin && git status    # 1. 同步检查
git pull origin <branch>           # 2. 如有落后，先 pull
git add <files>
git commit -m "<type>: <message>" # 3. 提交
git diff <base>..HEAD              # 4. 展示 diff 给你确认
git pull origin <branch>           # 5. pre-push safety
git push origin <branch>           # 6. 推送
```

---

### 阶段 ⑧：Contract Verify（前后端联调）

**触发条件**：代码已推送，前后端都跑起来了

**开发阶段（实时校验）**：
- 前端 axios 拦截器读取 api-spec.yaml
- 每个响应自动校验 Schema
- 字段不对 -> 红屏提示

**联调阶段（总验收）**：
- 读取 api-spec.yaml
- 逐接口发请求
- AJV 校验响应
- 生成契约验证报告

**通过标准**：所有接口 Schema 100% 匹配

---

### 阶段 ⑨：Integration Test（流程联调）

**触发条件**：Contract Verify 通过，准备 Archive

**检查项**：
- [ ] .openspec.yaml 存在且格式正确
- [ ] proposal.md / design.md / tasks.md 齐全
- [ ] tasks.md 所有任务已勾选
- [ ] design.md 引用了 proposal.md
- [ ] specs/ 和 design.md 匹配
- [ ] 代码已提交，Git 历史规范
- [ ] 工作区干净，无未提交修改

---

### 阶段 ⑩：Archive（归档）

**触发条件**：Integration Test 通过

**操作步骤**：
1. AI 检查 artifact 完成度
2. AI 检查 tasks 完成度
3. AI 检查 delta specs：
   - 如有 -> 展示 summary -> 你确认是否 sync
4. AI 执行归档：
   ```
   mkdir -p openspec/changes/archive
   mv openspec/changes/<name> openspec/changes/archive/YYYY-MM-DD-<name>
   ```
5. AI 输出归档摘要

---

## 五、技能清单速查表

| 技能 | 阶段 | 作用 | 触发方式 |
|------|------|------|---------|
| openspec-explore | ① Explore | 需求调研、澄清问题 | 手动：/opsx-explore |
| openspec-propose | ② Propose | 生成设计文档 | 手动：/opsx-propose |
| openspec-apply-change | ③ Apply | 按任务实现代码 | 手动：/opsx-apply |
| dynamic-test | ③⑤ | 生成测试、联调工具 | 自动/手动 |
| quality-gate | ④ | AI 自检四层关卡 | 自动触发 |
| code-review | ⑤ | 红蓝对抗评审 | 自动触发 |
| user-review-gate | ⑥ | 强制用户审查 | 自动触发（AI 停住） |
| git-sync-guard | ⑦ | 提交前同步检查 | 自动触发 |
| contract-verify | ⑧ | 契约验证总验收 | 手动/CI |
| dev-schema-guard | ⑧ | 开发时实时校验 | 前端拦截器 |
| integration-test | ⑨ | 流程闭环验证 | 手动/CI |
| openspec-archive-change | ⑩ | 归档变更 | 手动：/opsx-archive |
| openspec-sync-specs | ⑩ | 同步 specs 到主目录 | archive 时调用 |

---

## 六、常见问题

### Q1：AI 生成的代码有 bug 怎么办？

**流程**：
1. User Review Gate 时发现 -> 直接说"修改"或"重做"
2. 已提交后发现 -> 新建一个 change "fix-xxx-bug"，走完整流程
3. 紧急修复 -> 可以跳过 Explore/Propose，直接 Apply，但要在 commit message 里注明 "hotfix"

### Q2：前后端并行开发，接口对不上？

**预防**：
- Propose 阶段生成 api-spec.yaml，前后端都以此为契约
- Apply 阶段各自实现
- Verify 阶段用 contract-verify 验证

### Q3：AI 写的代码风格不一致？

**解决**：
- project-context/00-global/coding-standard.md 定义统一风格
- Quality Gate L2 自动检查规范合规
- Code Review 检查代码异味

### Q4：模型选型怎么选？

**原则**：
- 需要理解大量代码库 -> Kimi-k2.6 / Claude Sonnet 200k（长上下文）
- 需要深度推理 -> DeepSeek-v4-pro / o3（逻辑严密）
- 追求速度 -> GPT-4o / Gemini Flash（快）
- 测试 Debug -> DeepSeek-v4-flash / GPT-4o-mini（便宜）

### Q5：流程太长了，能不能简化？

**可以，但不建议跳过用户审查**：
- 快速模式：Quality Gate + User Review -> Git Commit（跳过 Code Review）
- 原型模式：Explore -> Apply -> User Review -> Commit（跳过 Propose 详细设计）
- 紧急修复：直接 Apply -> User Review -> Commit（跳过 Explore/Propose）

**底线**：User Review Gate 和 Git Sync Guard 不能跳过
