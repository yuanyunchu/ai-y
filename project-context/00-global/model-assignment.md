# AI 模型匹配方案：六层研发模型

> 基于「按环节匹配模型特性」理念：上下文长度 ↔ 推理深度 ↔ 响应速度 ↔ 成本
> 此文件为 project-context 全局上下文，AI 在启动任务前应读取以确定使用哪个模型

---

## 一、模型矩阵总览

```
         上下文长度                        推理深度
              │                               │
     环节①    │                      环节②③   │
    ┌─────────┼─────────┐           ┌─────────┼─────────┐
    │  长上下文模型       │           │   深度推理模型      │
    │  Kimi-k2.6        │           │  DeepSeek-v4-pro  │
    │  Claude 200k      │           │  o3 / o3-mini     │
    └───────────────────┘           └───────────────────┘
              │                               │
        读取代码库                        因果推理
        + PRDs                          架构设计
        + 文档

         响应速度                           
              │                           
     环节④⑤  │                           
    ┌─────────┼──────────┐     ┌───────────────────┐
    │  高速代码模型        │     │   轻量快反模型       │
    │  Ark-code-latest   │     │  DeepSeek-v4-flash │
    │  GPT-4o            │     │  GPT-4o-mini       │
    │  Gemini Flash      │     │  Gemini Flash      │
    └────────────────────┘     └───────────────────┘
              │                            │
        CRUD 量产                     Bug 修复
        API 生成                      日志分析
        单元测试                       脚本编写
```

---

## 二、各环节模型详细配置

### 环节 ①：需求与调研 → OpenSpec Explore

| 属性 | 值 |
|------|-----|
| **首选模型** | Kimi-k2.6 / Claude 3.5 Sonnet (200k) |
| **备选模型** | Claude Sonnet 系列长上下文模型 |
| **核心能力** | 长上下文（≥128k tokens），吞食大量代码和文档 |
| **目标指标** | 召回率（不能漏掉关键信息） |
| **输出格式** | OpenSpec `proposal.md` + `ai-analysis.md` |
| **成本级别** | 高（10x baseline），建议先提取摘要再深度分析 |
| **输入类型** | 目录结构、核心 Entity、Feign 接口、PRD、Issue 列表、前端路由+Store模块 |
| **OpenSpec 阶段** | Explore |
| **输出位置** | `openspec/changes/<name>/proposal.md`<br>`project-context/01-requirement/ai-analysis/<name>.md` |
| **关键规则** | 限定上下文范围，微服务优先给 common-api + Gateway 路由<br>前端优先给路由配置 + Store 模块 + 页面目录<br>关键结论需人工 grep 二次确认<br>前后端同步分析，避免理解不一致 |

---

### 环节 ②：架构与设计 → OpenSpec Propose

| 属性 | 值 |
|------|-----|
| **首选模型** | DeepSeek-v4-pro |
| **备选模型** | o3 / o3-mini / Claude 3.7 Sonnet (thinking mode) |
| **核心能力** | 深度推理，因果分析和逻辑严密性 |
| **目标指标** | 准确率（设计决策必须有充分理由） |
| **输出格式** | OpenSpec `design.md` + `frontend-design.md` + `specs/<capability>/spec.md` |
| **成本级别** | 高（5x baseline），开启推理模式仅用于设计阶段 |
| **输入类型** | proposal.md + ai-analysis.md + 非功能需求 |
| **OpenSpec 阶段** | Propose |
| **输出位置** | `openspec/changes/<name>/design.md`<br>`openspec/changes/<name>/specs/<capability>/spec.md`<br>`project-context/02-design/<name>/`（api-spec.yaml, db-schema.sql, sentinel-rules.json, frontend-design.md） |
| **关键规则** | 必须做服务拆分合理性判断<br>数据库设计满足第三范式或说明反范式理由<br>跨服务接口必须设计幂等性和超时重试<br>分布式事务方案避开长事务<br>前端设计必须与后端 API 契约对齐 |

---

### 环节 ③：核心开发 → OpenSpec Apply（攻坚）

| 属性 | 后端 | 前端 |
|------|------|------|
| **首选模型** | DeepSeek-v4-pro | DeepSeek-v4-pro / Claude 3.7 Sonnet |
| **备选模型** | o3-mini-high / Claude 3.7 Sonnet | o3-mini-high |
| **核心能力** | 理解深层依赖和边界条件 | 理解复杂交互逻辑和组件边界 |
| **目标指标** | 逻辑完整性（零重大 Bug） | 逻辑完整性（零重大 Bug） |
| **输出格式** | Java 源码（Controller → Service → Mapper） | Vue 组件 + Vuex Store + API |
| **成本级别** | 高（5x baseline） | 高（5x baseline） |
| **输入类型** | design.md + architecture.md + 现有参考代码 | frontend-design.md + api-spec.yaml + 现有参考组件 |
| **OpenSpec 阶段** | Apply | Apply |
| **输出位置** | `project-context/03-core/<name>/` + 实际项目源码 | `project-context/03-core/<name>/frontend/` + 实际项目源码 |
| **关键规则** | 先输出伪代码，确认后输出正式代码<br>禁止直接合入，需对抗性审查<br>复杂度不超过 O(n log n) | 先输出组件伪代码/交互流程<br>禁止直接合入，需对抗性审查<br>权限和状态管理逻辑需人工确认 |

---

### 环节 ④：标准开发 → OpenSpec Apply（量产）

| 属性 | 后端 | 前端 |
|------|------|------|
| **首选模型** | Ark-code-latest | Ark-code-latest |
| **备选模型** | GPT-4o / Gemini 2.5 Flash | GPT-4o / Gemini 2.5 Flash |
| **核心能力** | 高速生成，快速响应 | 高速生成，快速响应 |
| **目标指标** | 吞吐量（一次生成整个模块） | 吞吐量（一次生成整个页面模块） |
| **输出格式** | CRUD 代码、DTO/VO/Converter、单元测试、Feign 接口 | 列表页、表单页、详情页、API 文件、Store、路由 |
| **成本级别** | 低（1x baseline），批量生成减少往返 | 低（1x baseline），批量生成减少往返 |
| **输入类型** | api-spec.yaml + 数据库表结构 | api-spec.yaml + frontend-design.md |
| **OpenSpec 阶段** | Apply | Apply |
| **输出位置** | `project-context/04-standard/generated/` + 实际项目源码 | `project-context/04-standard/generated/frontend/` + 实际项目源码 |
| **关键规则** | 可批量生成一个完整模块<br>人工快速 Review 即可 | 可批量生成一个完整页面模块<br>人工快速 Review 即可，重点看字段映射和空值兜底 |

---

### 环节 ⑤：测试与 Debug → OpenSpec Apply（收尾）

| 属性 | 值 |
|------|-----|
| **首选模型** | DeepSeek-v4-flash |
| **备选模型** | GPT-4o-mini / Gemini Flash |
| **核心能力** | 毫秒级响应，极低成本 |
| **目标指标** | 响应速度（秒级交互） |
| **输出格式** | 修复代码（diff 格式）、分析报告、临时脚本 |
| **成本级别** | 极低（0.1x baseline），适合高频使用，但需配额监控和日志脱敏 |
| **输入类型** | 错误日志（需脱敏）、Stack Trace、浏览器控制台报错、相关代码 |
| **OpenSpec 阶段** | Apply / Archive |
| **输出位置** | `project-context/05-debug/bug-fixes.md` |
| **关键规则** | 日志脱敏后再给 AI<br>前端报错需脱敏 Cookie/Authorization<br>快问快答，不需要长上下文<br>使用模型最小版本追求速度 |

---

## 三、OpenSpec 阶段与模型选择决策树

```
收到需求变更
    │
    ├─ 需要理解业务 / 分析影响面？
    │   └─ YES → 环节① 长上下文模型 (Kimi/Claude 200k) → Explore
    │
    ├─ 需要设计方案 / 定义 API / 数据库建模？
    │   └─ YES → 环节② 深度推理模型 (DeepSeek-v4-pro/o3) → Propose
    │
    ├─ 需要写复杂算法 / 框架代码？
    │   └─ YES → 环节③ 代码专家模型 (DeepSeek-v4-pro/o3) → Apply(攻坚)
    │
    ├─ 需要批量生成 CRUD / DTO / UT？
    │   └─ YES → 环节④ 高速代码模型 (Ark-code/GPT-4o) → Apply(量产)
    │
    ├─ 需要查 Bug / 看日志 / 写脚本？
    │   └─ YES → 环节⑤ 轻量快反模型 (Flash/Mini) → Apply(收尾)
    │
    ├─ 前后端都跑起来了 / 需要联调验证？
    │   └─ YES → 环节⑥ contract-verify + dev-schema-guard → Apply(收尾)→ Archive
    │
    └─ 全部完成？
        └─ YES → Archive → 同步 specs + 更新项目基线 + RAG 归档
```

---

## 四、成本控制速查

| 环节 | 模型类型 | 相对成本 | 省钱技巧 |
|------|---------|---------|---------|
| ① | 长上下文 | 10x | 先轻量提取摘要，再深度分析，通常能显著降低长上下文调用成本 |
| ②③ | 深度推理 | 5x | 推理模式仅用于设计，代码阶段关闭深度思考 |
| ④ | 高速代码 | 1x | 批量生成，减少往返次数 |
| ⑤ | 轻量快反 | 0.1x | 适合高频使用，但注意日志脱敏自动化和调用配额 |
| ⑥ | 轻量快反 | 0.1x | 契约验证为脚本自动化，AI 仅用于生成 Schema 和分析报告 |

---

## 五、上下文包传递链

```
project-context/00-global/coding-standard.md ──→ 所有后端环节均作为 system prompt
project-context/00-global/frontend-standard.md ──→ 所有前端环节均作为 system prompt
project-context/00-global/api-conventions.yaml ──→ 环节②④ 必读
project-context/00-global/architecture-baseline.md ──→ 环节①② 必读
project-context/00-global/frontend-architecture.md ──→ 环节①② 前端必读
project-context/00-global/ai-harness.md ──→ 所有环节的评测、执行、回归与报告留痕

环节① 输出 (proposal + ai-analysis + 前端影响清单)  ──→ 环节② 输入
环节② 输出 (design + frontend-design + specs + tasks) ──→ 环节③④ 输入
环节③④ 输出 (后端源码 + 前端源码 + UT)              ──→ 环节⑤ 输入（如遇 Bug）
Harness 报告 (cases + reports)                      ──→ Prompt/模型回归与 Bad Case 复盘
Archive 归档                                        ──→ 下个迭代 RAG 知识库
```

---

> 维护人：架构组
> 最后更新：2026-05-29
> 关联文档：AGENTS.md, AI驱动研发流程-模型匹配方案.md
