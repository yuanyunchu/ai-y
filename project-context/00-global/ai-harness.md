# AI Harness 基线：评测、执行与回归

> 本文件是 AI 驱动研发流程的横切基线。
> 目标不是再增加一个模型环节，而是让每次 AI 调用、文档产出、代码生成和联调验证都可复现、可评分、可回归。
> 关联文件：`model-assignment.md`、`api-conventions.yaml`、`frontend-standard.md`、`AI驱动研发流程-模型匹配方案.md`

---

## 1. 定位

AI Harness 是六层模型流程之外的横切层：

```text
需求/设计/代码任务
    │
    ├─ 选择模型与上下文包（model-assignment.md）
    │
    ├─ 执行 Harness
    │   ├─ Prompt Harness：同一任务比较不同模型/Prompt
    │   ├─ Artifact Harness：检查 OpenSpec 文档完整性和一致性
    │   ├─ Code Harness：隔离运行生成代码、测试、构建、静态检查
    │   ├─ Contract Harness：验证前后端 OpenAPI/Schema 契约
    │   └─ Trace Harness：记录模型、Prompt、成本、耗时、评分、失败案例
    │
    └─ 产出 OpenSpec artifact / patch / report
```

核心原则：

1. **同输入可复现**：同一任务必须能记录模型、Prompt、上下文文件、代码基线、执行命令和输出结果。
2. **先低成本评，再高成本跑**：Prompt/文档质量先用规则和轻量模型筛掉明显错误，再调用深度推理或长上下文模型。
3. **代码必须执行验证**：代码类产物不能只靠模型自评，必须跑 lint、unit test、build、contract test 或最小复现脚本。
4. **失败样本要沉淀**：每个失败样本进入 `project-context/06-harness/cases/`，用于后续 Prompt 和模型回归。

---

## 2. 工具选型

| Harness 类型 | 覆盖环节 | 推荐工具 | 使用边界 |
|--------------|----------|----------|----------|
| Prompt Harness | ①②③④⑤ | Promptfoo | 适合 YAML 化测试用例、模型矩阵、断言和回归测试 |
| Artifact Harness | ①② | DeepEval / Inspect AI / 自定义 scorer | 评估 `proposal.md`、`design.md`、`spec.md` 是否完整、一致、可执行 |
| Code Harness | ③④⑤ | 自建 runner + SWE-bench 思路 | 隔离运行补丁、测试、构建和最小复现，不直接照搬公开 benchmark |
| Contract Harness | ⑥ | 自建 `contract-verify` + `dev-schema-guard` | 读 `api-spec.yaml`，校验真实接口响应和前端 Schema |
| Trace Harness | 全流程 | MLflow / LangSmith / 自建 JSONL | 记录输入、输出、token、耗时、成本、得分和失败样本 |

优先级建议：

1. 先自建轻量 Harness：Markdown 规则检查、OpenSpec 文件检查、测试命令编排、JSON 报告。
2. 再引入 Promptfoo：做 Prompt 和模型矩阵回归。
3. 再引入 DeepEval 或 Inspect AI：做复杂文档质量、agent 轨迹和工具调用评估。
4. 最后考虑 MLflow/LangSmith：当团队需要跨项目的实验记录和可视化追踪时再接入。

---

## 3. 与六层流程的映射

| 研发环节 | Harness 检查点 | 最低门禁 |
|----------|----------------|----------|
| ① 需求与调研 Explore | `proposal.md` 结构检查、影响面抽样核对、待澄清问题检查 | Why / What / Capabilities / Impact 完整；关键结论有文件或接口依据 |
| ② 架构与设计 Propose | `design.md`、`spec.md`、`tasks.md` 一致性检查 | 每个 capability 有 Scenario；每个 Scenario 能映射到 task；风险有缓解策略 |
| ③ 核心开发 Apply（攻坚） | 伪代码审查、代码执行、单测、对抗评审 | 核心路径有测试；复杂度和边界条件说明完整；禁止未验证直接合入 |
| ④ 标准开发 Apply（量产） | 批量生成一致性、lint、单测、字段映射检查 | DTO/VO/API/页面字段与 `api-spec.yaml` 对齐 |
| ⑤ 测试 Debug | 日志脱敏检查、最小复现、回归测试 | 修复必须绑定失败用例或复现命令 |
| ⑥ 联调验证 | `contract-verify`、`dev-schema-guard`、联调报告 | Archive 前 contract 全部 PASS 或有明确豁免记录 |

---

## 4. 推荐目录

```text
project-context/06-harness/
├── README.md                         # 使用说明和运行入口
├── cases/                            # 回归用例：需求、Prompt、失败样本
│   └── <change-name>.yaml
├── prompts/                          # 可版本化 Prompt 模板
│   ├── explore-proposal.md
│   ├── propose-design.md
│   └── apply-code-review.md
├── scorers/                          # 自定义评分器或规则检查
│   ├── openspec-artifact-check.md
│   └── code-quality-check.md
├── runners/                          # 本地执行脚本说明或封装
│   ├── run-openspec-check.md
│   ├── run-code-check.md
│   └── run-contract-check.md
└── reports/                          # 每次执行报告
    └── <date>-<change-name>-harness-report.json
```

真实脚本可按项目技术栈逐步落地到 `scripts/`、`tests/contract/` 或 CI workflow 中；`project-context/06-harness/` 负责保存用例、评分标准和报告索引。

---

## 5. 报告格式

每次 Harness 执行至少记录以下字段：

```json
{
  "change": "add-points-deduction",
  "phase": "propose",
  "model": "DeepSeek-v4-pro",
  "prompt_version": "propose-design@2026-05-29",
  "context_files": [
    "openspec/changes/add-points-deduction/proposal.md",
    "project-context/00-global/api-conventions.yaml"
  ],
  "checks": [
    {
      "name": "openspec_artifact_complete",
      "status": "pass",
      "score": 1.0
    },
    {
      "name": "api_contract_consistency",
      "status": "fail",
      "score": 0.6,
      "message": "frontend-design.md missing pointsDeduction response mapping"
    }
  ],
  "cost": {
    "input_tokens": 0,
    "output_tokens": 0,
    "estimated_cost": "manual"
  },
  "result": "fail",
  "next_action": "补齐前端响应字段映射后重跑"
}
```

---

## 6. Promptfoo 最小用法

适用场景：同一个 OpenSpec 任务，用不同模型或不同 Prompt 版本生成 `proposal.md`，比较结构完整性、关键字段覆盖率和人工评分。

```yaml
description: openspec-proposal-regression

prompts:
  - file://project-context/06-harness/prompts/explore-proposal.md

providers:
  - openai:gpt-4o
  - openai:gpt-4o-mini

tests:
  - vars:
      requirement: "订单支持积分抵扣"
      context: "order-service, user-service, payment-service"
    assert:
      - type: contains
        value: "## Why"
      - type: contains
        value: "## What Changes"
      - type: contains
        value: "## Impact"
      - type: llm-rubric
        value: "输出必须列出受影响服务、API、数据库表和前端页面。"
```

---

## 7. Artifact Scorer 规则

OpenSpec 文档先用规则评分，再考虑 LLM-as-judge：

| 文件 | 规则评分 | LLM 评分 |
|------|----------|----------|
| `proposal.md` | 必须包含 Why / What Changes / Capabilities / Impact | 影响面是否合理，有无遗漏上下游 |
| `design.md` | 必须包含 Context / Goals / Decisions / Risks | 决策是否有理由，风险是否有缓解策略 |
| `spec.md` | 每个 Requirement 至少一个 Scenario；Scenario 必须有 WHEN/THEN | 场景是否覆盖正常、异常、边界 |
| `tasks.md` | 每个任务可执行、可验证、能映射到 spec | 粒度是否合理，有无混杂任务 |

Archive 前必须有一份 Harness 报告，说明哪些检查通过、哪些豁免、哪些风险进入后续迭代。

---

## 8. Code Harness 最小门禁

核心开发和标准开发必须至少执行：

```text
1. git diff --check
2. 后端：mvn test / ./mvnw test（按项目实际命令）
3. 前端：npm test / npm run lint / npm run build（按项目实际命令）
4. OpenSpec：openspec validate <change-name>（如已安装）
5. 契约：contract-verify（前后端都可运行时）
```

如果某项无法执行，报告必须写明：

- 未执行命令
- 未执行原因
- 替代验证方式
- 残余风险

---

## 9. Bad Case 回流

每个 AI 失败案例必须沉淀为回归用例：

```yaml
id: badcase-2026-05-29-missing-api-field
phase: propose
symptom: frontend-design.md 未映射后端新增字段 pointsDeductionAmount
expected_guardrail:
  - api-spec.yaml 字段必须映射到 frontend-design.md 页面字段或说明不展示
regression_prompt: project-context/06-harness/prompts/propose-design.md
related_files:
  - openspec/changes/add-points-deduction/design.md
  - project-context/02-design/add-points-deduction/api-spec.yaml
```

---

## 10. 参考资料

- Promptfoo：适合 Prompt/模型矩阵、断言和回归测试。https://www.promptfoo.dev/docs/intro/
- DeepEval：适合 LLM 输出质量指标和 G-Eval 类自定义评分。https://deepeval.com/docs/metrics-llm-evals
- OpenAI Evals：适合把评估作为应用开发流程的一部分。https://platform.openai.com/docs/guides/evals
- Inspect AI：适合 task / solver / scorer 结构化评测和 agent 工具调用评估。https://inspect.aisi.org.uk/
- SWE-bench Harness：适合参考“任务输入、隔离运行、测试判定”的代码评测结构。https://www.swebench.com/SWE-bench/api/harness/
- SWE-agent：适合参考 GitHub issue 到代码修改、测试反馈的 agent 执行流程。https://github.com/SWE-agent/SWE-agent
- MLflow Eval-Driven Development：适合参考评估数据集、逐条失败分析、迭代回归。https://mlflow.org/cookbook/eval-driven-development
- LangSmith Evaluation：适合参考 trace、dataset、experiment 和 human/LLM feedback。https://www.langchain.com/langsmith/evaluation

---

> 维护人：架构组
> 最后更新：2026-05-29
