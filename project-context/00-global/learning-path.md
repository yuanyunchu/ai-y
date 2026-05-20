# AI 驱动研发 — 新人学习指南 v1.0

> 从传统开发平滑过渡到 AI 辅助开发，从「写代码」变成「管理 AI 写代码」

---

## 一、先搞清楚：AI 驱动研发是什么

### 不是让 AI 替你写代码那么简单

```
传统开发：  需求 → 你写代码 → 你测试 → 你部署
AI 开发：   需求 → AI 调研 → AI 设计 → AI 写代码 → AI 自检 → 你审查 → 你提交
```

**核心变化**：你的角色从「执行者」变成「审查者+决策者」

| 你的新角色 | 做什么 | 不需要做什么 |
|-----------|--------|-------------|
| 需求决策者 | 判断做什么、为什么做 | 不需要自己想方案 |
| 设计审查者 | 审查 AI 的架构方案对不对 | 不需要自己画架构图 |
| 代码审查者 | 审查 AI 写的代码有没有 bug | 不需要自己写 CRUD |
| 质量把关者 | 最终拍板通过还是重做 | 不需要自己写测试用例 |

---

## 二、先看一遍全局流程（10 分钟看懂）

```
你有个需求
    │
    ▼
① Explore（需求调研）           "帮我调研一下积分扣减功能"
    产出：proposal.md            AI 分析现状，澄清需求
    │
    ▼
② Propose（架构设计）           "生成设计方案"
    产出：design.md + tasks.md   AI 设计技术方案，拆分任务
    │
    ▼
③ Apply（AI 写代码）            "开始实现"
    产出：代码 + 测试            AI 按任务清单逐项编码
    │
    ▼
④ Quality Gate（AI 自检）      【自动执行】
    L1-L4 四层检查              AI 检查语法/规范/逻辑/测试
    │
    ▼
⑤ Code Review（红蓝对抗）       【自动执行，可选】
    不同模型交叉评审             AI 用另一模型审查代码
    │
    ▼
⑥ User Review Gate（你审查）    【必须你参与】
    通过 / 修改 / 重做          你看代码，决定是否通过
    │
    ▼
⑦ Git Sync Guard（提交推送）    【自动+你确认】
    fetch → commit → 你确认 → push  规范化提交
    │
    ▼
⑧ Integration Test（流程联调）   【可自动执行】
    验证文件完整、上下文连贯      检查整个流程是否闭环
    │
    ▼
⑨ Archive（归档）              "归档"
    移入 archive/ 目录           关闭本次变更，同步 specs
```

**关键原则**：你只需要在 ① 和 ⑥ 两个环节深度参与，其他环节 AI 自动处理。

---

## 三、第一步：安装和初始化

### 3.1 你需要什么

- Node.js 20.19+（OpenSpec CLI 需要）
- Git
- 本项目 testpro 克隆到本地

### 3.2 安装 OpenSpec CLI

```bash
npm install -g @fission-ai/openspec@latest
```

### 3.3 初始化项目

```bash
cd your-business-project          # 进入你的业务项目
openspec init                     # 初始化 OpenSpec
```

初始化后会生成：
```
openspec/
├── specs/          ← 系统规范（已有功能是怎么工作的）
├── changes/        ← 变更目录（每次需求一个文件夹）
└── config.yaml     ← 项目配置
```

---

## 四、实战：跟着走一遍完整流程

### 场景：给积分系统增加「积分抵扣」功能

#### Step 1：发起需求调研

> 对 AI 说：「Explore 一下，我想给积分系统增加积分抵扣功能，用户下单时可以用积分抵扣部分金额」

AI 会：
1. 读取现有的积分系统代码和文档
2. 问澄清问题：「抵扣比例是多少？」「有没有最低消费限制？」
3. 输出一个 proposal.md，描述为什么要做、做什么、影响哪些模块

你只需要：
- 回答 AI 的问题
- 确认 proposal.md 的内容对不对

---

#### Step 2：生成设计方案

> 对 AI 说：「生成设计方案」

AI 会自动：
1. 生成 design.md — 技术方案（数据库表、API 接口、服务调用链）
2. 生成 api-spec.yaml — API 契约（前后端对接的依据）
3. 生成 tasks.md — 任务清单（包含「创建积分抵扣表」「实现扣减接口」等子任务）

你只需要：
- 看一眼架构图对不对（比如是不是用了 Redis 而不是 MQ）
- 确认 API 路径对不对（`/api/v1/points/deduct` 还是 `/api/v1/deduction`）

---

#### Step 3：AI 写代码

> 对 AI 说：「开始实现」

AI 会自动按 tasks.md 逐项编码：
- 写 Controller → Service → Mapper
- 写单元测试（JUnit + Mockito）
- 每完成一项就标记 [x]

你不需要操作，等 AI 做完即可。

---

#### Step 4：AI 自检

AI 会自动跑 Quality Gate：
- L1：检查语法错误 → 有的话自动修
- L2：检查命名规范 → 不符合的话提示你
- L3：检查空值处理 → 有遗漏的话提示你
- L4：检查测试覆盖 → 不达标的话提示你

AI 会汇报检查结果，小问题自动修，大问题等你决定。

---

#### Step 5：你审查（最关键的一步）

AI 会把所有改动展示给你：

```
## 待审查变更（3 个文件）

1. src/service/PointsService.java  — 修改（新增 deduct() 方法）
2. src/controller/PointsController.java — 修改（新增 /deduct 接口）
3. src/test/.../PointsServiceTest.java  — 新增

请审查。选项：通过 / 修改 / 重做 / 讨论
```

你可以：
- 「通过」→ 没问题，提交保存
- 「改下第 25 行，积分扣减应该用事务」→ AI 修改后重新审查
- 「这个方案不对，应该用 Redis 而不是数据库」→ AI 重做
- 「为什么用悲观锁而不是乐观锁？」→ AI 解释，你再决定

**最重要**：没你说「通过」，AI 不会保存任何代码。

---

#### Step 6：提交推送

你说「通过」后，AI 会：
1. `git fetch origin && git status`（检查远程有没有新提交）
2. `git add && git commit`
3. 展示 diff 给你看
4. 等你确认后 `git push`

---

#### Step 7：联调测试

如果你有前端项目：
- 开发阶段：axios 拦截器自动校验后端返回的字段对不对
- 联调阶段：AI 读取 api-spec.yaml，逐接口发请求，生成验证报告

如果你只有后端：
- AI 帮你生成 curl 命令 / Postman 集合 / Mock 数据
- AI 帮你跑集成测试（`@SpringBootTest` + H2 内存库）

---

#### Step 8：归档

> 对 AI 说：「归档」

AI 会把 `openspec/changes/add-points-deduction/` 移入 `archive/`，并同步 specs。

---

## 五、技能速查：什么时候用什么

| 你说的话 | AI 触发什么 | 用在哪个环节 |
|---------|-----------|------------|
| 「Explore 一下 XXX」 | openspec-explore | ① 需求调研 |
| 「生成设计方案」 | openspec-propose | ② 架构设计 |
| 「开始实现」 | openspec-apply-change | ③ AI 写代码 |
| 「给 XxxService 写单元测试」 | dynamic-test | ③⑤ 测试 |
| 「跑一下质量关卡」 | quality-gate | ④ AI 自检 |
| 「跑一下代码评审」 | code-review | ⑤ 红蓝对抗 |
| 「通过 / 改下第 X 行 / 重做」 | user-review-gate | ⑥ 你审查 |
| 「提交」 | git-sync-guard | ⑦ 提交推送 |
| 「生成 Postman 集合 / curl」 | dynamic-test | ⑧ 联调 |
| 「跑一下联调测试」 | integration-test | ⑨ 流程验证 |
| 「归档」 | openspec-archive-change | ⑩ 归档 |

---

## 六、常见踩坑与对策

### 坑 1：AI 写的代码风格和自己不一样

**解法**：把你的编码规范写入 `project-context/00-global/coding-standard.md`，AI 会自动遵守。

### 坑 2：AI 漏了空值判断 / 边界条件

**解法**：Code Review（红蓝对抗）环节会自动检查，另外你在 User Review 时重点关注这些。

### 坑 3：前后端接口对不上

**解法**：Propose 阶段生成的 `api-spec.yaml` 是前后端共同契约。开发阶段 `dev-schema-guard` 会实时报错。

### 坑 4：AI 改了一个文件但影响了别的功能

**解法**：每次变更独立一个 change 文件夹，归档时自动同步 specs，下次 AI 会读到更新后的规范。

### 坑 5：模型选型不对，生成质量差

**解法**：六层模型帮你自动选型：
- 看代码/文档 → Kimi-k2.6 / Claude 200k（长上下文）
- 设计方案 → DeepSeek-v4-pro / o3（深度推理）
- 写 CRUD → GPT-4o / Gemini Flash（速度快）
- 修 Bug → DeepSeek-v4-flash（便宜快反）

---

## 七、进阶：外部学习资源

### 官方资源

| 资源 | 地址 | 适合 |
|------|------|------|
| OpenSpec 官网 | https://openspec.dev | 了解 SDD 理念 |
| OpenSpec Getting Started | https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md | 理解 Delta Spec 机制（ADDED/MODIFIED/REMOVED） |
| Agent Skills 标准 | https://agentskills.io | 学会写 Skill，检查 Skill 格式是否符合标准 |

### 中文教程

| 资源 | 地址 | Stars | 适合 |
|------|------|-------|------|
| OpenSpec 实践指南 | https://github.com/ForceInjection/OpenSpec-practise | 340+ | 中文最完整教程+Node.js/Python 两套 DEMO，推荐第一个看 |
| Superpowers+OpenSpec | https://github.com/SYZ-Coder/superpowers-openspec-team-skills | 94 | 有记忆系统，参考跨会话记忆用法 |
| DDD Skills 全景图 | https://github.com/ForceInjection/domain-driven-design-skills | 9 | DDD→OpenSpec 桥接，业务领域建模参考 |
| OpenSpec Schemas 社区 | https://github.com/JiangWay/openspec-schemas | 63 | 社区贡献的 Schema，可参考或贡献通用 schemas |

### 社区

| 资源 | 地址 |
|------|------|
| OpenSpec Discord | https://discord.gg/YctCnvvshC |
| Agent Skills Discord | https://discord.gg/MKPE9g8aUy |

---

## 八、学习路线图

```
第 1 天：看一遍这个文档，理解全局流程（30 分钟）
    │
第 2 天：装好 OpenSpec CLI，用 ForceInjection/OpenSpec-practise 的 ecommerce-mini 跑一遍（2 小时）
    │
第 3 天：在自己的 Spring Boot 项目里走一遍完整流程（4 小时）
    │
    ├─ Explore：提一个真实需求，让 AI 出 proposal.md
    ├─ Propose：生成 design.md + api-spec.yaml
    ├─ Apply：让 AI 写代码
    ├─ Quality Gate：看 AI 自检报告
    ├─ Code Review：看红蓝对抗评审结果
    ├─ User Review：你亲自审查代码 ← 重点体会这一环节
    └─ Archive：归档变更
    │
第 4-7 天：重复第 3 天的流程，做 3-5 个小需求，形成肌肉记忆
    │
第 2 周：开始定制
    ├─ 修改 coding-standard.md 匹配你的团队规范
    ├─ 修改 api-conventions.yaml 匹配你的接口约定
    └─ 尝试 dynamic-test（生成 curl/Postman/集成测试）
    │
第 3 周：进阶
    ├─ 配置 contract-verify（前后端联调）
    ├─ 参考 SYZ-Coder 的 memory 系统（跨会话记忆）
    ├─ 了解 OpenSpec Schemas 社区，贡献通用 schemas
    └─ 如有 DDD 需求，参考 domain-driven-design-skills（DDD→OpenSpec 桥接）
```

---

## 九、术语速查

| 术语 | 解释 |
|------|------|
| **OpenSpec** | 规范驱动开发框架，让你和 AI 在写代码前先对齐需求 |
| **Change** | 一次需求变更，对应 `openspec/changes/<name>/` 一个文件夹 |
| **Spec** | 规格说明，描述系统应该怎么做 |
| **Delta Spec** | 增量规格，描述本次变更相对于当前系统改了什么 |
| **Proposal** | 需求提案（Why + What） |
| **Design** | 技术方案（How） |
| **Task** | 实现任务清单 |
| **Quality Gate** | AI 自检的四层关卡（L1 语法 → L4 测试） |
| **红蓝对抗** | 用不同架构的 AI 交叉审查代码 |
| **Agent Skill** | AI 的技能包（一个 SKILL.md 文件 = 一个技能） |
| **SDD** | Spec-Driven Development，规范驱动开发 |
| **DDD** | Domain-Driven Design，领域驱动设计 |

---

## 十、一句话总结

> **传统开发你写代码，AI 驱动你审查代码。AI 负责「做出来」，你负责「做对了」。**

有问题随时在对话里问，我就是你的 AI 编程搭档。