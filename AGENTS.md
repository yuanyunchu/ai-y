# AGENTS.md — AI 驱动研发 × OpenSpec 融合指南

## 核心原则

**按研发环节匹配模型特性**：上下文长度 ↔ 推理深度 ↔ 响应速度 ↔ 成本
AI 生成的所有文档必须符合 OpenSpec 格式，走 Explore → Propose → Apply → Archive 标准流程。
所有阶段必须接入 AI Harness 留痕：记录模型、Prompt、上下文、执行检查、评分、失败样本和残余风险。

---

## 六层模型 × OpenSpec 映射

| 研发环节 | OpenSpec 阶段 | 推荐模型 | 选型逻辑 | 产出物 |
|---------|--------------|---------|---------|--------|
| **① 需求与调研** | **Explore** | Kimi-k2.6 / Claude Sonnet 200k | 长上下文，吞食代码库和文档，召回率优先 | `proposal.md` + `project-context/01-requirement/ai-analysis/` |
| **② 架构与设计** | **Propose** | DeepSeek-v4-pro / o3 / Claude 3.7 thinking | 深度推理，因果分析和逻辑严密性 | `design.md` + `specs/` + `project-context/02-design/` |
| **③ 核心开发（后端）** | **Apply（攻坚）** | DeepSeek-v4-pro / o3-mini-high | 理解深层依赖和边界条件 | 核心算法/框架层代码 |
| **③ 核心开发（前端）** | **Apply（攻坚）** | DeepSeek-v4-pro / Claude 3.7 Sonnet | 理解复杂交互逻辑和状态管理 | 核心组件/权限/SDK封装 |
| **④ 标准开发（后端）** | **Apply（量产）** | Ark-code-latest / GPT-4o / Gemini Flash | 追求吞吐量和响应速度 | CRUD/API/UT 样板代码 |
| **④ 标准开发（前端）** | **Apply（量产）** | Ark-code-latest / GPT-4o / Gemini Flash | 追求吞吐量和响应速度 | 列表页/表单页/详情页 样板代码 |
| **⑤ 测试 Debug** | **Apply（收尾）** / Archive | DeepSeek-v4-flash / GPT-4o-mini | 毫秒级响应，几乎零成本 | 修复代码 + `bug-fixes.md` |
| **⑥ 前后端联调验证** | **Apply（收尾）→ Archive** | DeepSeek-v4-flash / GPT-4o-mini | 契约校验 + 联调报告 | 契约验证报告 + Schema 拦截器 |

AI Harness 是横切层，不占用研发环节编号：Prompt Harness 做模型/Prompt 回归，Artifact Harness 做 OpenSpec 文档检查，Code Harness 做测试/构建/最小复现，Contract Harness 做前后端契约验证，Trace Harness 做成本和失败样本留痕。

---

## 上下文传递铁律

1. **下游必读上游**：环节③的 Prompt 开头必须包含 "基于 proposal.md / design.md / architecture.md..."
2. **禁止跨环节**：标准开发模型不能直接读原始需求，必须读设计文档
3. **Harness 留痕**：进入 Archive 前必须保留 `project-context/06-harness/reports/` 报告，记录已执行检查、未执行原因和残余风险
4. **定期归档**：迭代结束后 Archive，同步 specs 到 `openspec/specs/`，存入 RAG 知识库

---

## 红蓝对抗评审

核心代码完成后，用不同架构的模型做 Code Review：

| 开发模型 | 评审模型 | 评审重点 |
|---------|---------|---------|
| DeepSeek-v4-pro | Claude 3.7 / o3-mini | 边界条件、并发安全、异常处理 |
| Kimi-k2.6 | DeepSeek-v4-pro | 逻辑一致性、架构合规性 |
| GPT-4o | Claude 3.5 Sonnet | 代码异味、过度工程 |

---

## 关键规则

- 环节① 必须限定上下文范围，先给 common-api + Gateway 路由，再深入目标服务；前端需提供路由配置 + 状态管理模块
- 环节②③ 必须要求 AI 先输出伪代码、步骤分解、关键决策依据和边界条件清单，确认后再输出正式代码
- 环节③ 核心代码禁止直接合入，必须经过 Code Review 或对抗性审查
- 环节④ 允许 AI 直接生成后人工快速 Review
- 环节⑤ 日志脱敏后再给 AI；前端需提供浏览器控制台报错 + 网络请求
- 环节⑥ 前后端联调验证：开发阶段用 dev-schema-guard 实时校验，联调阶段用 contract-verify 总验收
- AI Harness：Archive 前必须执行或记录 Prompt/Artifact/Code/Contract Harness 结果，报告存入 `project-context/06-harness/reports/`
- 全局规范文件位于 `project-context/00-global/`，所有 AI 调用应将其作为 system prompt 上下文
- Harness 规范见 `project-context/00-global/ai-harness.md`
- 前端编码规范见 `project-context/00-global/frontend-standard.md`，前端架构见 `project-context/00-global/frontend-architecture.md`

---

## 前后端联调验证（环节⑥）

| 阶段 | 工具 | 时机 | 说明 |
|------|------|------|------|
| 开发阶段 | `dev-schema-guard` | 前端开发时实时 | axios 拦截器校验响应 Schema，字段不对立即红屏提示 |
| 联调阶段 | `contract-verify` | 前后端都跑起来后 | 读 api-spec.yaml → 逐接口发请求 → AJV 校验 → 出报告 |
| Archive 前 | `contract-verify` | 最终验收 | 契约全通过才能归档 |

---

## 项目结构

```
openspec/changes/<name>/    # 变更级：Explore → Propose → Apply → Archive
project-context/            # 项目级：全局架构基线、编码规范、API 约定
project-context/06-harness/ # AI Harness 用例、Prompt、评分标准、报告
```

完整模型分配细则见 `project-context/00-global/model-assignment.md`
