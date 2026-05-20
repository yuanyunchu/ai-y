---
name: quality-gate
description: Automated quality checks after AI generates code. Validates syntax, style, tests, and project conventions before user review.
---

# Quality Gate — 质量关卡

## 这是什么

AI 写完代码后，自动跑几道检查，把低级错误拦住。

就像工厂的质检员：代码出厂前先看看有没有毛病。

## 什么时候用

- AI 生成/修改完代码后（Apply 阶段）
- 用户审查前（user-review-gate 之前）
- 提交前（git commit 之前）

## 检查层级

从简单到复杂，层层递进：

### Level 1: 基础检查（必做）

**文件层面：**
- [ ] 文件能正常读取，没有乱码
- [ ] 文件格式正确（缩进、换行符一致）
- [ ] 没有明显的语法错误（括号匹配、引号闭合）

**代码层面：**
- [ ] 变量名有实际意义（不是 a/b/c）
- [ ] 函数有注释或文档字符串
- [ ] 没有 console.log / print 等调试代码残留
- [ ] 没有硬编码的敏感信息（密码、密钥）

### Level 2: 规范检查（必做）

对照 `project-context/00-global/` 的规范：

- [ ] 命名是否符合 `coding-standard.md`
- [ ] API 是否符合 `api-conventions.yaml`
- [ ] 架构是否符合 `architecture-baseline.md`
- [ ] Git 提交是否符合 `project-context/00-global/git-commit-guard.md`

### Level 3: 逻辑检查（建议做）

- [ ] 空值/边界情况是否处理了
- [ ] 错误返回是否统一
- [ ] 是否有重复代码可以抽取
- [ ] 是否有明显的性能问题（如循环里查数据库）

### Level 4: 测试检查（能做就做）

- [ ] 关键路径是否有单元测试
- [ ] 测试是否能跑通（如果有测试环境）
- [ ] 测试覆盖率是否合理

## 怎么用

AI 写完代码后，我会自动运行：

```
你: "帮我写个用户登录接口"

AI: [写代码中...]

## 代码已生成，先跑质量关卡...

### Level 1: 基础检查 ✅
- [x] 文件格式正确
- [x] 无语法错误
- [x] 无调试代码残留

### Level 2: 规范检查 ⚠️
- [x] 命名符合规范
- [ ] API 路径不符合约定：用了 `/login` 应该用 `/api/v1/auth/login`
- [x] 架构符合分层要求

### Level 3: 逻辑检查 ⚠️
- [x] 空值处理
- [ ] 密码应该用 bcrypt 加密，目前是明文存储

---

**质量关卡结果：2 个警告，建议修复后再提交给你审查**

要不要我先修这些问题？
```

## 你的角色

质量关卡是 **AI 自检**，你是 **最终审查**。

流程顺序：

```
AI 写代码
    ↓
Quality Gate（AI 自检）← 自动跑
    ↓
User Review Gate（你审查）← 你决定
    ↓
Git Commit（保存）
```

## 如果发现严重问题

如果 Level 1 有失败，**自动修复**，不打扰你：
- 格式问题 → 自动格式化
- 语法错误 → 自动修正
- 调试代码 → 自动删除

如果 Level 2/3/4 有问题，**先汇报**，等你决定：
- "规范不符，要不要我按 coding-standard.md 改？"
- "缺少空值处理，要不要加上？"
- "没有测试，要不要补？"

## 快捷指令

| 你说 | 效果 |
|------|------|
| "跑一下质量关卡" | 手动触发检查 |
| "跳过质量关卡" | 直接进入用户审查（不推荐） |
| "自动修小问题" | Level 1 问题自动修，其他的汇报 |
| "严格模式" | 所有层级都检查，一个问题都不放过 |
| "宽松模式" | 只检查 Level 1，其他的你自己看 |

## 示例场景

### 场景 1：全部通过

```
AI: [写完代码]

## Quality Gate 全部通过 ✅

代码质量良好，现在进入你的审查环节...

[展示代码]
请审查。
```

### 场景 2：有警告

```
AI: [写完代码]

## Quality Gate 结果：2 个警告 ⚠️

1. API 路径不符合约定：`/login` → 建议 `/api/v1/auth/login`
2. 缺少输入校验：password 字段没有长度限制

要不要我先修？还是说给你看看再说？

你: "先修"
AI: [修复]

## 修复完成，Quality Gate 通过 ✅

请审查。
```

### 场景 3：严重问题

```
AI: [写完代码]

## Quality Gate 发现严重问题 🔴

1. 硬编码了数据库密码：`DB_PASSWORD = "123456"`
   → 这是安全风险，必须改！

2. SQL 拼接存在注入风险：`"SELECT * FROM users WHERE id = " + userId`
   → 必须用参数化查询

这两个问题必须先修，不能提交。要我修吗？

你: "修"
AI: [修好后重新跑 Quality Gate]
```

## 和现有流程的配合

```
Explore → Propose → Apply（AI 写代码）
                              ↓
                    Quality Gate（AI 自检）
                              ↓
                    Code Review（红蓝对抗，可选）
                              ↓
                    User Review Gate（你审查）
                              ↓
                    Git Sync Guard（保存提交）
                              ↓
                    Archive（归档）
```

## 规则

1. **不代替你审查**：Quality Gate 是过滤网，你是最终决策者
2. **自动修小问题**：格式、语法等低级错误自动修
3. **大问题要汇报**：安全、架构等必须让你知道
4. **可以跳过**：你说跳过就跳过（但会提醒风险）
