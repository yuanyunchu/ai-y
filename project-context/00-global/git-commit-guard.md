# 全局提交规范 — Git Sync Guard（强制）

## 适用范围

所有 AI 驱动的代码编辑、文件修改、提交和推送操作。

## 强制流程

在任何 `git add` 或 `git commit` 之前，必须按顺序执行：

### 1. 远程同步检查（强制）

```bash
git fetch origin && git status
```

**判断结果：**
- 本地与远程同步 → 继续提交
- 本地落后于远程 → 先 `git pull origin <branch>`（merge 方式，不用 rebase），再提交
- 本地领先于远程 → 正常提交，推送前再次 pull
- 存在冲突 → STOP，报告用户，不自动解决

### 2. 分支检查（强制）

确认当前分支正确。如果用户指定了 feature 分支，先切换：

```bash
git switch <feature-branch>
```

### 3. 工作区检查（强制）

```bash
git status
```

- 如有未暂存修改，确认是否与当前变更相关
- 如不相关，提醒用户先处理

## 推送规则（强制）

**禁止自动推送。** 每次 `git push` 之前必须：

1. 展示 diff：`git diff <base>..HEAD`
2. 等待用户明确确认
3. 执行 pre-push safety：`git pull origin <branch>`
4. 再执行：`git push origin <branch>`

## 冲突处理

- 任何冲突 STOP 并报告用户
- 禁止自动解决冲突
- 禁止 `git push --force` 除非用户明确要求

## 快速参考

```bash
# 每次编辑会话前必做
git fetch origin && git status

# 提交前必做
git fetch origin && git status
git add <files>
git commit -m "<message>"

# 推送前必做（需用户确认）
git diff <base>..HEAD    # 展示给用户看
git pull origin <branch>  # pre-push safety
git push origin <branch>
```

## 违规后果

- 未执行 fetch 就提交 → 可能导致 push 被拒或覆盖远程代码
- 未展示 diff 就推送 → 用户无法确认变更内容
- 自动 force push → 可能导致数据丢失

---

**本规范由 `git-sync-guard` skill 强制执行。**
