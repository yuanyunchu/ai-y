# AI 驱动研发流程方案：模型匹配 × OpenSpec 融合规范

> 基于「按环节匹配模型特性」理念：上下文长度 ↔ 推理深度 ↔ 响应速度 ↔ 成本
> **AI 生成文档必须遵循 OpenSpec 格式：Explore → Propose → Apply → Archive**
> 适用团队：需要规模化使用 AI 辅助研发的工程团队
> 文档状态：V1.3 OpenSpec 融合版

---

## 一、总体架构：五层模型矩阵

把研发流程拆解为 5 个环节，每个环节匹配最适合的 AI 特性：

| 研发环节 | OpenSpec 阶段 | 核心任务 | 推荐模型 | 选型逻辑 | 产出物位置 |
|---------|--------------|---------|---------|---------|-----------|
| **① 需求与调研** | **Explore** | 读历史代码、分析文档、梳理业务 | Kimi-k2.6, Claude 3.5/4 Sonnet 200k | 吞食大量代码库和文档，**召回率**第一 | `openspec/changes/<name>/proposal.md`<br>`project-context/01-requirement/ai-analysis/<name>.md` |
| **② 架构与设计** | **Propose** | 后端架构+前端架构、数据库设计、模块解耦 | DeepSeek-v4-pro, o1/o3, Claude 3.7 thinking | 因果推理和逻辑严密性，**准确率**优先 | `openspec/changes/<name>/design.md`<br>`openspec/changes/<name>/specs/<cap>/spec.md`<br>`project-context/02-design/<name>/` |
| **③ 核心开发（后端）** | **Apply（攻坚）** | 复杂算法、框架层代码、性能优化 | DeepSeek-v4-pro, o3-mini-high, Claude 3.7 | 理解深层依赖和边界条件，**逻辑完整性**优先 | `openspec/changes/<name>/tasks.md` 核心任务<br>`project-context/03-core/<name>/` |
| **③ 核心开发（前端）** | **Apply（攻坚）** | 复杂交互、权限封装、SDK封装、状态管理 | DeepSeek-v4-pro, Claude 3.7 Sonnet | 理解复杂交互逻辑和组件边界，**逻辑完整性**优先 | `project-context/03-core/<name>/frontend/` |
| **④ 标准开发（后端）** | **Apply（量产）** | CRUD、API 接口、单元测试、样板代码 | Ark-code-latest, GPT-4o, Gemini 2.5 Flash | **吞吐量和响应速度**，成本敏感 | `openspec/changes/<name>/tasks.md` 标准任务<br>`project-context/04-standard/generated/` |
| **④ 标准开发（前端）** | **Apply（量产）** | 列表页、表单页、详情页、API对接 | Ark-code-latest, GPT-4o, Gemini 2.5 Flash | **吞吐量和响应速度**，成本敏感 | `project-context/04-standard/generated/frontend/` |
| **⑤ 测试与 Debug** | **Apply（收尾）/ Archive** | 查日志、修 Bug、写脚本、格式化数据 | DeepSeek-v4-flash, GPT-4o-mini, Gemini Flash | **毫秒级响应**，几乎零成本 | `project-context/05-debug/bug-fixes.md` |

---

## 二、各环节标准作业流程（SOP）

---

### 环节 ①：需求与调研（信息消化层）→ OpenSpec Explore

**目标**：让 AI 成为项目的"资深老员工"，掌握全部业务背景。

#### OpenSpec 映射
- **阶段**：Explore
- **模型**：长上下文模型（Kimi-k2.6 / Claude 200k）
- **输入**：代码库 + PRD + Issue 列表
- **输出**：`proposal.md` + `ai-analysis.md`
- **成本**：10x baseline（限制输入长度，先提取摘要再分析）

#### 输入
- 历史代码库（重点看目录结构、核心实体、接口定义）
- **微服务全景**：服务拆分图、Nacos 服务列表、Gateway 路由配置
- **跨服务契约**：`common-api` 模块中的 Feign 接口、DTO、共享枚举
- **前端代码库**：路由配置、Vuex Store 模块、页面组件目录结构
- 产品需求文档 / API 文档 / 数据库字典
- 相关 Issue / 会议纪要

#### 标准 Prompt 模板（后端）
```text
你是一位熟悉本项目的高级架构师。请阅读以下代码库和文档，完成以下任务：
1. 【业务理解】总结系统的核心业务流程和领域模型
2. 【服务边界】梳理当前微服务拆分是否合理，指出可能存在的领域边界模糊点
3. 【影响面分析】如果我要新增 [XXX] 功能，会涉及哪些服务、模块和表？
4. 【接口梳理】列出与 [XXX] 相关的所有 API（含内部 Feign 接口）及其调用链路
5. 【技术债扫描】指出代码库中明显的设计缺陷、重复逻辑或过度拆分

【输出格式要求】
请将分析结果按以下 OpenSpec Proposal 格式输出：
## Why（为什么要做这个功能）
## What Changes（具体变更内容）
## Capabilities（新增/修改的能力点）
## Impact（影响的服务、API、数据库表）

[粘贴代码片段或上传代码压缩包]
```

#### 标准 Prompt 模板（前端）
```text
你是一位熟悉本项目的前端架构师。请阅读以下前端代码库和文档，完成以下任务：
1. 【页面梳理】列出与 [XXX] 功能相关的所有页面、组件和路由
2. 【状态管理】梳理相关 Vuex Store 模块，分析哪些状态需要新增/修改
3. 【组件复用】识别可复用的现有组件，以及需要新建的组件
4. 【API 对接】列出需要调用的后端接口，分析数据格式是否与前端需求匹配
5. 【影响面分析】新增 [XXX] 功能会影响哪些页面、路由、菜单和权限

【输出格式要求】
请将分析结果追加到 OpenSpec Proposal 的 Impact 部分：
## Impact-Frontend（影响的前端页面、组件、路由、状态）

[粘贴前端代码片段或目录结构]
```

#### 输出物
- `openspec/changes/<name>/proposal.md` — OpenSpec 标准提案（Why / What / Capabilities / Impact + Impact-Frontend）
- `project-context/01-requirement/ai-analysis/<name>.md` — AI 详细分析
- 业务领域模型图（文本版 Mermaid）
- **服务依赖拓扑图**（哪些服务调用了哪些服务）
- **前端页面/组件/路由影响清单**
- 待澄清问题清单（交给产品经理）

#### 关键规则
- ⚠️ **必须限定上下文范围**：微服务仓库多，优先给 `common-api` 和 Gateway 路由配置，再深入目标服务
- ⚠️ **交叉验证**：长上下文模型有时会"幻觉"遗漏细节，关键结论需用 `grep` 或 `ripgrep` 人工二次确认
- ⚠️ **前后端同步分析**：需求调研必须同时覆盖后端 API 和前端页面，避免前后端理解不一致

---

### 环节 ②：架构与设计（决策层）→ OpenSpec Propose

**目标**：产出高可维护性的技术方案（后端 + 前端），避免后期返工。

#### OpenSpec 映射
- **阶段**：Propose
- **模型**：深度推理模型（DeepSeek-v4-pro / o3 / Claude 3.7 thinking）
- **输入**：proposal.md + ai-analysis.md + 非功能需求
- **输出**：`design.md` + `specs/<capability>/spec.md` + `tasks.md` + `frontend-design.md`
- **成本**：5x baseline（推理模式仅用于设计，写代码时关闭）

#### 输入
- 环节 ① 的输出（领域模型 + 影响面 + 前端影响清单）
- 非功能性需求（QPS、延迟、一致性要求）

#### 标准 Prompt 模板（后端）
```text
基于以下业务需求和技术现状，请设计技术方案：
1. 【服务拆分】判断是否需新建服务或复用现有服务，说明理由
2. 【架构设计】给出模块划分和跨服务交互时序（用 Mermaid 时序图）
3. 【数据设计】给出核心表结构（MyBatis-Plus），要求：
   - 标注索引策略
   - 说明分库分表/分区策略（如需）
   - 给出迁移方案（如需改表）
4. 【接口契约】定义核心 API 的 Request/Response 和错误码
5. 【非功能设计】
   - 幂等性方案（Token / 数据库唯一索引 / 状态机）
   - 限流熔断策略（Sentinel 规则）
   - 分布式事务方案（Seata AT / TCC / Saga，默认 AT）
   - 缓存策略（Redis + Caffeine 二级缓存，如需）
6. 【风险清单】列出 3 个最大的技术风险及应对策略

约束条件：
- 技术栈：Java 17 + Spring Boot 3.x + Spring Cloud Alibaba 2022.x
- ORM：MyBatis-Plus（唯一选择，禁止引入 JPA / Hibernate）
- 缓存：Redis + Caffeine（本地二级缓存如需引入需说明理由）
- 消息队列：RocketMQ（已有基础设施）
- 注册/配置中心：Nacos
- 网关：Spring Cloud Gateway
- 限流熔断：Sentinel
- 分布式事务：Seata（AT 模式优先）
- 链路追踪：Micrometer Tracing + Zipkin
- 禁止引入新的中间件/框架（除非充分说明理由，并附带迁移成本评估）
```

#### 标准 Prompt 模板（前端）
```text
基于以下业务需求和后端 API 设计，请设计前端技术方案：
1. 【页面设计】给出新增/修改的页面清单，页面布局和交互流程（用文字描述关键交互）
2. 【路由设计】新增/修改的路由配置，含路由守卫和权限标识
3. 【状态管理】涉及的 Vuex Store 模块，新增/修改的 state/mutation/action
4. 【组件设计】
   - 可复用的现有组件列表
   - 需要新建的业务组件和基础组件
   - 组件 Props/Events 接口定义
5. 【API 对接】每个页面需要调用的后端接口，请求参数和响应数据映射
6. 【交互细节】
   - 表单校验规则
   - 加载/空/错误状态处理
   - 分页/搜索/筛选方案
7. 【风险清单】列出前端侧 3 个最大风险（如接口数据格式不匹配、复杂交互性能、兼容性等）

约束条件：
- 技术栈：Vue 2.x + Vuex 3.x + Vue Router 3.x
- UI 库：<!-- TODO: 填写 --> 
- CSS：<!-- TODO: 填写 -->
- 编码规范：遵循 project-context/00-global/frontend-standard.md
```

#### 输出物
- `openspec/changes/<name>/design.md` — OpenSpec 标准设计文档（Context / Goals / Decisions / Risks）
- `openspec/changes/<name>/specs/<capability>/spec.md` — 能力规格（WHEN/THEN）
- `openspec/changes/<name>/tasks.md` — 实现任务清单（含前端任务）
- `project-context/02-design/<name>/architecture.md` — 详细架构设计
- `project-context/02-design/<name>/api-spec.yaml` — OpenAPI 规范
- `project-context/02-design/<name>/db-schema.sql` — 数据库变更脚本
- `project-context/02-design/<name>/sentinel-rules.json` — 限流规则
- `project-context/02-design/<name>/frontend-design.md` — 前端设计方案

#### 质量门禁（必须人工 Review）
- [ ] 服务拆分粒度是否合理？（避免分布式单体或过度拆分）
- [ ] 数据库设计是否满足第三范式（或故意反范式化有理由）？
- [ ] 跨服务接口是否考虑了幂等性和超时重试？
- [ ] 分布式事务方案是否避开了长事务？
- [ ] 是否引入了不必要的复杂度？
- [ ] OpenSpec specs 中所有 Scenario 都有 WHEN/THEN？
- [ ] tasks.md 中任务是否可执行、粒度合理？
- [ ] 前端页面和组件设计是否与后端 API 对齐？
- [ ] 前后端接口契约是否一致（字段名、类型、枚举值）？

---

### 环节 ③：核心开发（攻坚层）→ OpenSpec Apply

**目标**：编写后端算法/框架层/复杂业务逻辑 + 前端复杂交互/权限/SDK，要求零重大 Bug。

#### OpenSpec 映射
- **阶段**：Apply（攻坚段）
- **模型（后端）**：代码专家模型（DeepSeek-v4-pro / o3-mini-high / Claude 3.7）
- **模型（前端）**：代码专家模型（DeepSeek-v4-pro / Claude 3.7 Sonnet）
- **输入**：design.md + frontend-design.md + specs/ + 参考代码
- **输出**：核心源码 + 复杂度分析 + 单元测试（覆盖率 ≥ 80%）
- **成本**：5x baseline

#### 输入
- `design.md` 中的核心模块（Context + Decisions + Risks）
- `frontend-design.md` 中的前端核心模块
- `specs/<capability>/spec.md` 中的 WHEN/THEN 场景
- `tasks.md` 中标记为"Core Implementation"的任务
- 现有类似代码的参考实现（Copy-Paste 给 AI 作为风格参考）

#### 标准 Prompt 模板（后端）
```text
请根据以下设计文档，实现 [XXX] 模块的核心代码（Java 17 + Spring Boot 3.x + SCA）。

要求：
1. 【风格一致性】参考以下现有代码的编码风格 [粘贴参考代码]，遵循阿里巴巴 Java 开发手册
2. 【分层规范】严格遵循 Controller → Service → Mapper 分层，禁止跨层调用
3. 【微服务规范】
   - 跨服务调用必须使用 Feign（定义在 common-api 模块），禁止直接 RestTemplate / HttpClient
   - Feign 接口必须写 FallbackFactory，熔断后返回降级数据或抛出自定义异常
   - 跨服务调用必须传递 trace_id（通过 Micrometer Tracing + MDC）
   - 写操作涉及多个服务时，使用 Seata @GlobalTransactional（AT 模式）
   - 接口必须考虑幂等性（使用数据库唯一索引或 Redis Token 机制）
4. 【防御性编程】
   - 所有外部输入必须使用 @Valid / @Validated 校验
   - 所有写操作必须有 @Transactional（单服务）或 @GlobalTransactional（跨服务），并指定传播行为
   - 所有 RPC / Feign 调用必须设置超时和重试（connectTimeout / readTimeout / maxAttempts）
5. 【边界条件】显式处理 null（使用 Optional / Objects.requireNonNull）、并发（锁粒度最小化，优先 Redis 分布式锁）、超时场景
6. 【性能】
   - 时间复杂度不超过 O(n log n)
   - 禁止 N+1 查询，复杂查询使用 MyBatis-Plus Join 或手写 XML
   - 批量操作使用 MyBatis-Plus saveBatch / updateBatch，阈值控制在 500 条/批
7. 【可观测性】关键路径必须打印结构化日志（trace_id, span_id, user_id, cost_ms），使用 SLF4J + MDC
8. 【异常处理】统一使用自定义 BusinessException，禁止在业务层捕获后吞掉异常

请先输出核心流程的伪代码，确认无误后再输出完整的 Java 实现代码。
```

#### 标准 Prompt 模板（前端）
```text
请根据以下前端设计文档，实现 [XXX] 模块的核心前端代码（Vue 2.x + Vuex + Vue Router）。

要求：
1. 【风格一致性】参考以下现有代码的编码风格 [粘贴参考代码]，遵循 project-context/00-global/frontend-standard.md
2. 【组件规范】
   - 组件命名必须多词，PascalCase
   - Props 必须定义类型和默认值
   - 组件销毁时必须清理副作用（setTimeout / EventBus / watch）
3. 【状态管理】
   - 异步操作放 Action，Mutation 必须同步
   - Store 模块按业务拆分，命名遵循 模块/动作
4. 【权限控制】
   - 路由权限：通过 meta 配置权限标识，路由守卫统一拦截
   - 按钮权限：使用 v-permission 指令或权限函数
5. 【API 对接】
   - 接口调用使用 async/await，统一错误处理
   - 响应数据与后端 Result<T> 对齐
6. 【防御性编程】
   - 所有表单必须校验（必填、格式、长度）
   - 接口返回数据做兜底处理（避免 undefined/null 导致页面崩溃）
   - 列表渲染必须处理空状态和加载状态
7. 【性能】
   - 路由懒加载：() => import()
   - 大列表使用虚拟滚动（如需）
   - 避免不必要的 watchers 和 computed 依赖
8. 【安全】
   - 禁止 v-html（除非 DOMPurify 过滤）
   - 用户输入做 XSS 防护
   - Token 过期自动跳转登录

请先输出核心组件的伪代码/交互流程，确认无误后再输出完整的 Vue 实现代码。
```

#### 输出物
- 后端核心模块源码 → `project-context/03-core/<name>/`
- 前端核心组件源码 → `project-context/03-core/<name>/frontend/`
- 复杂算法的复杂度分析
- 单元测试（覆盖率 ≥ 80%）

#### 关键规则
- ⚠️ **必须要求 AI 输出"思考过程"**：让模型先写伪代码或步骤分解，再输出正式代码，能大幅降低逻辑错误
- ⚠️ **禁止直接合入**：核心代码必须经过 Code Review 或至少让另一个 AI 模型做"对抗性审查"
- ⚠️ **前后端核心代码需交叉 Review**：前端核心组件需确认后端接口契约一致性，后端需确认前端数据消费方式

---

### 环节 ④：标准开发（量产层）→ OpenSpec Apply

**目标**：快速产出后端 CRUD/DTO/Converter + 前端列表页/表单页/详情页等样板代码。

#### OpenSpec 映射
- **阶段**：Apply（量产后段）
- **模型**：高速代码模型（Ark-code-latest / GPT-4o / Gemini Flash）
- **输入**：api-spec.yaml + 数据库表结构 + frontend-design.md
- **输出**：全套后端标准代码 + 前端页面代码 + 单元测试
- **成本**：1x baseline（批量生成减少往返）

#### 输入
- `api-spec.yaml`
- 数据库表结构
- `frontend-design.md` 中的页面清单和组件设计

#### 标准 Prompt 模板（后端）
```text
根据以下 OpenAPI 规范和表结构，生成完整的 Java 代码（Spring Boot 3.x + MyBatis-Plus + SCA）：

分层要求：
- Controller 层：
  - 使用 @RestController + @RequestMapping
  - 入参使用 DTO + @Valid 校验
  - 返回统一包装类 Result<T>（Spring Boot 项目标准响应体：code / message / data）
  - 禁止使用 Map / JSONObject 作为返回类型
- Service 层：
  - 接口 + 实现类分离（IService + ServiceImpl）
  - 业务编排逻辑放在这里，禁止直接操作 Mapper
  - 单服务事务 @Transactional 写在 Service 实现类上
- Mapper 层：
  - 继承 BaseMapper<T>
  - 复杂查询写在对应的 XML 中（命名规范：EntityNameMapper.xml）
- 数据对象：
  - Entity：对应数据库表，仅用于持久层
  - DTO：入参对象，包含 @NotNull / @Size 等校验注解
  - VO：出参对象，禁止包含敏感字段（如密码、手机号明文）
  - Convertor：使用 MapStruct 转换，禁止手写 get/set 赋值
- common-api 模块（跨服务共享）：
  - Feign 接口 + FallbackFactory
  - 共享 DTO / VO / 枚举
  - 禁止在 common-api 中引入 Spring Boot Web / MyBatis 等重量级依赖
- 单元测试：
  - 使用 JUnit 5 + Mockito
  - Controller 层使用 @WebMvcTest
  - Service 层使用 @ExtendWith(MockitoExtension.class)

要求：
- 严格遵循 RESTful 规范，URL 使用 kebab-case（如 /user-orders）
- 使用 Lombok（@Data / @Builder / @RequiredArgsConstructor）
- 使用 MyBatis-Plus 的 Lambda 查询避免硬编码字段名
- 不要写注释，代码自解释即可（追求速度）
```

#### 标准 Prompt 模板（前端）
```text
根据以下后端 API 规范和前端设计，生成完整的 Vue 2 页面代码：

生成内容：
- API 请求文件（src/api/xxx.js）：
  - 每个接口一个函数，返回 Promise
  - 使用项目封装的 request 方法
- 页面组件（src/views/xxx/List.vue / Form.vue / Detail.vue）：
  - 列表页：搜索栏 + 表格 + 分页，含 loading/empty 状态
  - 表单页：新增/编辑复用，含表单校验
  - 详情页：信息展示，含返回按钮
- Vuex Store（如需）：
  - state / getters / mutations / actions 标准结构
- 路由配置（src/router/modules/xxx.js）：
  - 懒加载 () => import()
  - meta 含 title 和权限标识

要求：
- 严格遵循 project-context/00-global/frontend-standard.md 编码规范
- 使用 UI 库组件（<!-- TODO: 填写 UI 库名 -->）
- 响应数据与后端 Result<T> 对齐：res.data.data 为业务数据
- 分页参数与后端对齐：{ current, size }
- 表单校验规则完整（必填、格式、长度）
- 列表页必须处理：搜索重置、分页切换、loading 状态、空数据
- 表单页必须处理：新增/编辑模式切换、提交前校验、提交后刷新列表
- 使用 scoped 样式，遵循 BEM / kebab-case 命名
```

#### 输出物
- 后端全套标准代码文件 → `project-context/04-standard/generated/`
- `common-api` 模块的 Feign 接口 + DTO
- 前端页面代码文件 → `project-context/04-standard/generated/frontend/`
- 单元测试文件

#### 关键规则
- ✅ **允许 AI 直接生成后人工快速 Review**：重点检查字段映射、空指针、SQL 注入风险、Feign 路径是否正确
- ✅ **批量生成**：一次生成一个完整模块的所有样板代码，比单文件生成效率更高
- ✅ **前后端批量联调**：后端 API + 前端页面一起生成，减少前后端接口对不齐的问题

---

### 环节 ⑤：测试与 Debug（响应层）→ OpenSpec Apply / Archive

**目标**：快速定位问题、修复线上 Bug、编写临时脚本（后端 + 前端）。

#### OpenSpec 映射
- **阶段**：Apply（收尾）→ Archive
- **模型**：轻量快反模型（DeepSeek-v4-flash / GPT-4o-mini / Gemini Flash）
- **输入**：日志（脱敏后）+ Stack Trace + 浏览器控制台报错 + 代码片段
- **输出**：修复代码 + `bug-fixes.md`
- **成本**：0.1x baseline（无限使用）

#### 输入
- 错误日志 / Stack Trace（多服务日志，需通过 trace_id 串联）
- 前端浏览器控制台报错 / 网络请求错误（脱敏后）
- 相关代码片段
- Skywalking / Zipkin 链路追踪截图（如有）

#### 标准 Prompt 模板（后端查 Bug）
```text
以下是生产环境的错误日志和相关代码，请分析根因并给出修复方案。
日志已按 trace_id 聚合：

【链路追踪】
trace_id: xxx
涉及服务：gateway → order-service → payment-service

【日志】
[粘贴日志]

【代码】
[粘贴代码]

要求：
1. 先给出根因判断（用 1-2 句话概括，定位到具体服务和方法）
2. 给出修复后的代码（仅修改必要部分，用 diff 格式标注）
3. 说明如何预防此类问题再次发生（如加 Sentinel 规则、补 Fallback、加幂等）
```

#### 标准 Prompt 模板（前端查 Bug）
```text
以下是前端页面报错和相关代码，请分析根因并给出修复方案。

【浏览器控制台报错】
[粘贴报错信息]

【网络请求】
[粘贴失败请求的 URL / 状态码 / 响应体]

【相关代码】
[粘贴组件代码 / API 调用代码]

要求：
1. 先给出根因判断（用 1-2 句话概括，定位到具体组件和方法）
2. 给出修复后的代码（仅修改必要部分，用 diff 格式标注）
3. 说明如何预防此类问题（如加空值兜底、加 loading 防重复提交、加错误边界）
```

#### 标准 Prompt 模板（写脚本）
```text
请写一段 Python/Bash 脚本，功能：[描述需求]
要求：
- 可直接运行，无需额外依赖（或仅使用标准库）
- 处理异常情况（如文件不存在、网络超时）
- 输出结果用表格/JSON 格式化
```

#### 关键规则
- ⚠️ **日志脱敏**：给 AI 日志前，必须手动替换手机号、Token、密码等敏感信息
- ⚠️ **前端报错脱敏**：浏览器 Network 中的 Cookie、Authorization 头需脱敏
- ✅ **快问快答**：这一层完全不需要长上下文，追求的就是秒级响应，用最小模型即可

---

## 三、上下文传递规范与目录结构（双轨制）

模型分工只是基础，实践中最大的坑是**上下文丢失**。必须建立"研发上下文包"机制，采用 **OpenSpec 变更级 + project-context 项目级** 双轨制：

```
/home/yhy/testpro/
├── openspec/                          # 【变更级】OpenSpec 标准管理
│   ├── changes/
│   │   └── <change-name>/             # 每个需求一个变更目录
│   │       ├── .openspec.yaml         # 变更元数据（schema: spec-driven）
│   │       ├── proposal.md            # ← 环节① Explore 产物
│   │       ├── design.md              # ← 环节② Propose 产物
│   │       ├── specs/<cap>/spec.md    # ← 环节② 能力规格（WHEN/THEN）
│   │       └── tasks.md               # ← 环节② 实现任务清单
│   ├── specs/                         # 【项目级】主规格基线（Archive 后同步）
│   │   └── order-service/spec.md
│   └── changes/archive/               # 归档变更（历史记录 + RAG）
│       └── 2026-05-19-<change-name>/
│
└── project-context/                   # 【项目级】全局上下文
    ├── 00-global/                     # 全局规范基线
    │   ├── architecture-baseline.md   # 全栈架构（后端微服务 + 前端）
    │   ├── frontend-architecture.md   # 前端架构基线（Vue 2）
    │   ├── frontend-standard.md       # 前端编码规范速查
    │   ├── coding-standard.md         # 后端编码规范速查
    │   └── api-conventions.yaml       # API 全局约定
    ├── 01-requirement/
    │   ├── prd/                       # 原始需求文档
    │   └── ai-analysis/<name>.md      # 环节① AI 详细分析（含前端影响）
    ├── 02-design/<name>/
    │   ├── architecture.md            # 详细架构设计
    │   ├── frontend-design.md         # 前端设计方案
    │   ├── api-spec.yaml              # OpenAPI 规范
    │   ├── db-schema.sql              # 数据库变更
    │   └── sentinel-rules.json        # 限流规则
    ├── 03-core/<name>/                # 环节③ 核心代码
    │   └── frontend/                  #   前端核心组件
    ├── 04-standard/
    │   ├── generated/                 # 环节④ 后端可重生成代码
    │   │   └── frontend/              #   前端可重生成代码
    │   └── common-api/                # 跨服务 Feign 接口 + DTO
    └── 05-debug/
        └── bug-fixes.md               # Bug 复盘记录（前后端）
```

### 规则
1. **下游环节必须读取上游输出**：例如环节 ③ 的 Prompt 开头必须包含 "基于设计文档 [粘贴 design.md 核心内容]..."
2. **禁止跨环节直接给原始需求**：如果让标准开发模型直接读原始需求，它可能会忽略架构约束（如分布式事务、幂等性要求、前端组件规范）
3. **OpenSpec Artifact 必须完整**：每个变更必须有 proposal → design → specs → tasks，缺一不可才能进入 Apply 阶段
4. **定期归档**：迭代结束后执行 `openspec archive <change-name>`，同步 specs 到 `openspec/specs/`，将 `ai-analysis.md` 和 `design.md` 存入向量数据库作为 RAG 知识库
5. **项目级基线同步**：若变更新增服务/接口/全局规范/前端页面/路由，必须更新 `project-context/00-global/` 下的对应文件
6. **前后端上下文同步**：环节②必须同时产出后端设计和前端设计，确保接口契约一致

---

## 四、OpenSpec 质量门禁与 Archive 规范

### Apply 前质量门禁（必须人工 Review）

在从 Propose 进入 Apply 之前，必须满足以下门禁：

| 检查项 | 检查内容 | 对应文件 |
|--------|---------|---------|
| **提案完整性** | Why / What / Capabilities / Impact（含前端影响）是否完整 | `proposal.md` |
| **规格完整性** | 所有 Scenario 都有 WHEN/THEN，无遗漏 | `specs/<cap>/spec.md` |
| **设计完整性** | Context / Goals / Decisions / Risks 是否齐全 | `design.md` |
| **前端设计完整性** | 页面/路由/组件/状态管理/API 对接是否齐全 | `frontend-design.md` |
| **任务可执行性** | tasks.md 中每个任务粒度合理、可独立执行 | `tasks.md` |
| **架构合规性** | 服务拆分合理，数据库设计满足规范 | `architecture.md` |
| **接口规范性** | API Spec 符合 api-conventions.yaml 全局约定 | `api-spec.yaml` |
| **前后端契约一致性** | 前端请求参数/响应数据与后端 API Spec 对齐 | `api-spec.yaml` + `frontend-design.md` |

### Archive 归档流程

迭代结束或变更上线后，执行以下归档步骤：

```bash
# 1. 执行 OpenSpec 归档（自动同步 specs 到 openspec/specs/）
openspec archive <change-name>

# 2. 手动更新项目级基线（如新增服务/接口/全局规范）
# - 更新 project-context/00-global/architecture-baseline.md
# - 更新 project-context/00-global/api-conventions.yaml

# 3. RAG 知识库归档
# - 将 ai-analysis.md + design.md 向量化存入知识库
# - 更新团队 Wiki/Confluence
```

**归档命名规范**：`YYYY-MM-DD-<change-name>`（如 `2026-05-19-add-points-deduction`）

---

## 五、成本控制策略

| 模型类型 | 用途 | 预估成本（相对值） | 控制手段 |
|---------|-----|------------------|---------|
| 长上下文大模型 | 环节 ① | 10x | **限制输入长度**，先用工具提取关键文件，不要直接上传整个 Git 仓库 |
| 深度推理模型 | 环节 ②③ | 5x | 开启"推理模式"仅用于设计，写代码时关闭深度思考（如果模型支持） |
| 高速代码模型 | 环节 ④ | 1x | 批量生成，减少往返次数 |
| 轻量快反模型 | 环节 ⑤ | 0.1x | 无限使用，但注意日志脱敏工作流自动化 |

### 省钱技巧
- 环节 ① 可以先用 **轻量模型提取摘要**，再把摘要喂给长上下文模型做深度分析，成本降低 70%
- 环节 ④ 的单元测试可以用轻量模型生成，人工只 Review 边界条件

---

## 六、落地检查清单（Checklist）

如果你是技术负责人，按这个顺序落地：

- [ ] **Week 1**：选定各环节的模型供应商，申请 API Key，配置到 IDE（Cursor / Windsurf / Continue）
- [ ] **Week 2**：建立项目 `project-context/` 目录结构，把现有文档归类
- [ ] **Week 3**：编写各环节的标准 Prompt 模板，存入团队知识库（Notion / Confluence）
- [ ] **Week 4**：试运行一个完整需求（从需求评审到上线），记录 AI 产出质量，调整 Prompt
- [ ] **持续**：建立"Bad Case"复盘机制，把 AI 犯错的案例整理成"避坑指南"，更新到 Prompt 的系统提示词里

---

## 七、增强建议：对抗评审机制

在核心开发完成后，强制用另一个不同架构的模型做 Code Review，专门挑逻辑漏洞。

> 例如：如果开发用 DeepSeek，评审就用 Claude 或 o3-mini。

这个 **"红蓝对抗"机制** 能发现 90% 以上的 AI 幻觉导致的隐蔽 Bug。

| 开发模型 | 建议评审模型 | 评审重点 |
|---------|------------|---------|
| DeepSeek-v4-pro | Claude 3.7 Sonnet / o3-mini | 边界条件、并发安全、异常处理 |
| Kimi-k2.6 | DeepSeek-v4-pro | 逻辑一致性、架构合规性 |
| GPT-4o | Claude 3.5 Sonnet | 代码异味、过度工程 |

---

## 八、待细化事项（TODO）

以下内容需要结合 codexx 实际项目情况进一步补充：

- [x] **技术栈确认**：已确认为 Java + SCA 微服务生态
  - 语言：Java 17（LTS）
  - 框架：Spring Boot 3.x + Spring Cloud Alibaba 2022.x
  - ORM：MyBatis-Plus（唯一选择，禁止 JPA）
  - 注册/配置中心：Nacos
  - 网关：Spring Cloud Gateway
  - 服务调用：OpenFeign（必须配 FallbackFactory）
  - 限流熔断：Sentinel
  - 分布式事务：Seata（AT 模式优先）
  - 链路追踪：Micrometer Tracing + Zipkin
  - 消息队列：RocketMQ
  - 缓存：Redis + Caffeine
  - 工具库：Lombok、MapStruct、Hutool、Redisson
  - 测试：JUnit 5 + Mockito + AssertJ
  - 构建：Maven（pom.xml 统一管理版本号）
  - 容器：Docker + Kubernetes
- [ ] **模型供应商确认**：是否已接入 Ark / DeepSeek / Kimi API？Token 配额？
- [ ] **项目目录结构映射**：把 `project-context/` 规范映射到 codexx 实际仓库结构
- [ ] **Prompt 模板工程化**：是否使用 Dify / LangChain / 自研 Prompt 管理系统？
- [ ] **质量门禁自动化**：哪些检查可以接入 CI（如 API 规范校验、单元测试覆盖率）？
- [ ] **安全合规**：日志脱敏、代码审查、敏感信息扫描的自动化方案
- [ ] **度量体系**：如何量化 AI 提效（代码生成率、Bug 引入率、需求交付周期）？

---

---

## 附录 A：Java + SCA 微服务标准规范（AI 生成代码必须遵循）

### A.1 微服务模块结构规范

每个业务服务的 Maven 多模块结构：

```
xxx-service/                      # 业务服务根模块
├── xxx-api/                      # common-api：跨服务共享
│   ├── src/main/java/
│   │   └── com/codexx/xxx/api/
│   │       ├── feign/            # Feign 接口 + FallbackFactory
│   │       ├── dto/              # 共享 DTO（入参）
│   │       ├── vo/               # 共享 VO（出参）
│   │       └── enums/            # 共享枚举
│   └── pom.xml                   # 仅依赖 spring-cloud-openfeign-core，禁止 web/mybatis
└── xxx-biz/                      # 业务实现模块
    ├── src/main/java/
    │   └── com/codexx/xxx/biz/
    │       ├── controller/       # 仅负责：参数接收、权限校验、结果包装、路由映射
    │       ├── service/
    │       │   ├── impl/         # 业务逻辑实现，事务边界
    │       │   └── dto/          # 内部传输对象（本服务内 Service 间调用）
    │       ├── mapper/           # 数据访问层，仅 SQL 映射
    │       ├── entity/           # 数据库实体，与表一一对应
    │       ├── convertor/        # MapStruct 接口，Entity ↔ DTO ↔ VO 转换
    │       ├── vo/               # 返回给前端的视图对象
    │       ├── dto/              # 接收前端参数的入参对象（含校验注解）
    │       ├── enums/            # 本服务私有枚举
    │       ├── exception/        # 自定义异常 + 全局异常处理器
    │       └── config/           # 配置类，@Configuration
    └── pom.xml                   # 依赖 xxx-api + spring-boot-starter-web + mybatis-plus
```

**铁律**：
- `xxx-api` 模块禁止引入 `spring-boot-starter-web`、`mybatis-plus-boot-starter` 等重量级依赖
- `xxx-biz` 禁止直接暴露 Entity 给外部服务，跨服务数据传输必须经过 `xxx-api` 的 DTO/VO
- Controller 禁止直接调用 Mapper
- Service 禁止直接操作 HttpServletRequest / Response
- Entity 禁止出现在 Controller 的入参或返回值中

### A.2 命名规范

| 类型 | 规范 | 示例 |
|-----|------|------|
| 类名 | UpperCamelCase | `UserOrderServiceImpl` |
| 方法名 | lowerCamelCase | `getUserById` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| URL | kebab-case | `/user-orders/{order-id}` |
| 数据库表 | snake_case | `user_order` |
| 数据库字段 | snake_case | `created_at` |
| Feign 接口 | 以 `Feign` 结尾 | `OrderFeignClient` |
| FallbackFactory | 以 `FallbackFactory` 结尾 | `OrderFeignClientFallbackFactory` |
| common-api 模块 | 以 `-api` 结尾 | `order-api` |

### A.3 依赖注入规范

```java
// ✅ 推荐：构造器注入（Lombok 简化）
@RequiredArgsConstructor
@Service
public class UserServiceImpl implements IUserService {
    private final UserMapper userMapper;
    private final OrderService orderService;
    private final OrderFeignClient orderFeignClient; // 跨服务调用
}

// ❌ 禁止：字段注入
@Autowired
private UserMapper userMapper;
```

### A.4 异常处理规范

```java
// 自定义业务异常
public class BusinessException extends RuntimeException {
    private final Integer code;
    private final String message;
}

// Controller 层统一返回（Spring Boot 标准响应体）
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusinessException(BusinessException e) {
        return Result.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<Void> handleValidationException(MethodArgumentNotValidException e) {
        String msg = e.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining("; "));
        return Result.fail(400, msg);
    }
}
```

### A.5 日志规范

```java
// 使用 SLF4J + MDC 传递链路追踪 ID（Micrometer Tracing 自动注入）
// traceId 和 spanId 由 Micrometer 自动放入 MDC，无需手动生成
log.info("[orderCreate] traceId={}, spanId={}, userId={}, amount={}, costMs={}",
    MDC.get("traceId"), MDC.get("spanId"), userId, amount, costMs);

// 跨服务 Feign 调用时，traceId 会自动通过请求头传递（需配置 Brave 或 OpenTelemetry Propagator）
```

### A.6 数据库操作规范

```java
// ✅ 批量插入（MyBatis-Plus）
userMapper.insertBatchSomeColumn(userList); // 控制 500 条/批

// ✅ Lambda 查询（避免硬编码字段名）
userMapper.selectList(Wrappers.<User>lambdaQuery()
    .eq(User::getStatus, 1)
    .like(User::getName, keyword)
    .orderByDesc(User::getCreateTime)
    .last("LIMIT 100"));

// ✅ 分页查询（必须）
Page<User> page = new Page<>(current, size);
userMapper.selectPage(page, Wrappers.<User>lambdaQuery().eq(User::getStatus, 1));

// ✅ 复杂 SQL 手写 XML（命名空间必须与 Mapper 全限定名一致）
// UserMapper.xml: <select id="selectUserWithOrders" resultMap="...">

// ❌ 禁止在循环中查询数据库（N+1）
// ❌ 禁止手写全表 UPDATE / DELETE（必须用 Wrapper 限定条件）
```

### A.7 接口返回规范

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Result<T> {
    private Integer code;       // HTTP 状态码风格：200 = 成功，400 = 参数错误，500 = 系统错误
    private String message;     // 提示信息
    private T data;             // 业务数据
    private Long timestamp;     // 时间戳（毫秒）

    public static <T> Result<T> success(T data) {
        return new Result<>(200, "success", data, System.currentTimeMillis());
    }

    public static <T> Result<T> fail(Integer code, String message) {
        return new Result<>(code, message, null, System.currentTimeMillis());
    }
}
```

**说明**：此为 Spring Boot 项目最常见的标准统一响应体，不引入过度自定义的嵌套结构。网关层统一包装，业务层直接返回 `Result.success(data)`。

### A.8 Feign 接口规范

```java
// 定义在 common-api 模块
@FeignClient(
    name = "order-service",
    fallbackFactory = OrderFeignClientFallbackFactory.class,
    configuration = FeignConfig.class
)
public interface OrderFeignClient {
    @GetMapping("/orders/{orderId}")
    Result<OrderVO> getOrderById(@PathVariable("orderId") Long orderId);
}

// FallbackFactory 实现（必须）
@Component
@Slf4j
public class OrderFeignClientFallbackFactory implements FallbackFactory<OrderFeignClient> {
    @Override
    public OrderFeignClient create(Throwable cause) {
        log.error("order-service 调用降级", cause);
        return orderId -> Result.fail(503, "订单服务暂不可用，请稍后重试");
    }
}
```

**铁律**：
- Feign 接口必须定义在 `common-api` 模块，返回值必须是 `Result<T>`
- 必须配置 `fallbackFactory`，禁止只配 `fallback`
- Feign 接口的 URL 必须与目标服务 Controller 的 URL 完全一致

### A.9 微服务配置规范

#### Nacos 配置（`bootstrap.yml`）
```yaml
spring:
  application:
    name: order-service
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_SERVER:localhost:8848}
        namespace: ${NACOS_NAMESPACE:prod}
      config:
        server-addr: ${NACOS_SERVER:localhost:8848}
        namespace: ${NACOS_NAMESPACE:prod}
        file-extension: yaml
        shared-configs:
          - data-id: common.yaml
            group: DEFAULT_GROUP
            refresh: true
```

#### Sentinel 规则（代码定义或 Nacos 推送）
```java
@Configuration
public class SentinelConfig {
    @PostConstruct
    public void init() {
        // 接口限流：QPS = 100
        FlowRule rule = new FlowRule();
        rule.setResource("GET:/orders/{orderId}");
        rule.setGrade(RuleConstant.FLOW_GRADE_QPS);
        rule.setCount(100);
        FlowRuleManager.loadRules(Collections.singletonList(rule));
    }
}
```

#### Seata 分布式事务
```java
// 发起方（调用多个服务的入口）
@GlobalTransactional(rollbackFor = Exception.class, timeoutMills = 30000)
public void createOrder(CreateOrderDTO dto) {
    // 1. 本地事务：保存订单
    orderMapper.insert(order);
    // 2. 跨服务调用：扣减库存
    inventoryFeignClient.deduct(order.getSkuId(), order.getQuantity());
    // 3. 跨服务调用：扣减余额
    accountFeignClient.deduct(order.getUserId(), order.getAmount());
}
```

**铁律**：
- `@GlobalTransactional` 只能放在**事务发起方**（入口服务），被调用方只用 `@Transactional`
- 避免长事务：分布式事务总耗时控制在 3 秒以内
- Seata AT 模式要求：业务表必须有**主键**，且 UPDATE/DELETE 必须有**唯一条件**

---

> 文档维护人：@待填写
> 最后更新：2026-05-18
> 下次评审：待安排
