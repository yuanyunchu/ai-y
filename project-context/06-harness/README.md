# AI Harness 工作区

> 本目录用于沉淀 AI 研发流程的评测用例、Prompt 版本、评分标准和执行报告。
> 全局规范见 `project-context/00-global/ai-harness.md`。

## 目录约定

```text
project-context/06-harness/
├── cases/      # Prompt/模型/失败样本回归用例
├── prompts/    # 可版本化 Prompt 模板
├── scorers/    # 评分标准和自定义检查说明
├── runners/    # 本地执行脚本说明或封装入口
└── reports/    # Harness 执行报告
```

## 最小落地顺序

1. 先为一个真实 OpenSpec 变更补 `cases/<change-name>.yaml`。
2. 将 Explore / Propose / Apply 的稳定 Prompt 放入 `prompts/`。
3. 在 `scorers/` 写明文档完整性、契约一致性、代码执行检查规则。
4. 每次 Archive 前在 `reports/` 留存一次 Harness 报告。

## 报告要求

报告必须写明：

- 执行的 change name 和 OpenSpec 阶段
- 使用的模型、Prompt 版本、上下文文件
- 已执行检查项和结果
- 未执行检查项、原因和残余风险
- 下一步修复或豁免结论
