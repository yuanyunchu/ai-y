# 前端架构基线（Vue 2）

> 项目级全局文档，记录前端技术栈、架构方案和关键约定
> 任何变更若涉及前端架构调整、新增页面模块、变更路由或状态管理，必须更新本文档

---

## 1. 技术栈

| 类别 | 选型 | 版本 | 备注 |
|------|------|------|------|
| 框架 | Vue | 2.x | <!-- TODO: 填写具体版本，如 2.6.14 --> |
| UI 组件库 | <!-- TODO --> | <!-- TODO --> | <!-- TODO: Element-UI / Ant Design Vue / iView 等 --> |
| 状态管理 | Vuex | 3.x | <!-- TODO: 确认版本 --> |
| 路由 | Vue Router | 3.x | <!-- TODO: 确认版本 --> |
| HTTP 请求 | <!-- TODO --> | <!-- TODO --> | <!-- TODO: axios / flyio 等，附封装方案 --> |
| 构建工具 | <!-- TODO --> | <!-- TODO --> | <!-- TODO: webpack / vite (vue2+vite 需注意兼容) --> |
| CSS 预处理 | <!-- TODO --> | <!-- TODO --> | <!-- TODO: SCSS / Less / Stylus --> |
| 代码规范 | ESLint + Prettier | <!-- TODO --> | <!-- TODO: 附规则集 --> |
| 包管理器 | <!-- TODO --> | <!-- TODO --> | <!-- TODO: npm / yarn / pnpm --> |

---

## 2. 项目目录结构

```
<!-- TODO: 填写实际前端项目目录结构，参考下方模板 -->

src/
├── api/                    # 接口请求（按模块拆分）
│   ├── user.js
│   ├── order.js
│   └── points.js
├── assets/                 # 静态资源
│   ├── images/
│   ├── styles/             # 全局样式
│   └── fonts/
├── components/             # 公共组件
│   ├── common/             # 通用基础组件
│   └── business/           # 通用业务组件
├── directives/             # 自定义指令
├── filters/                # 全局过滤器
├── icons/                  # SVG 图标
├── layout/                 # 布局组件
├── mixins/                 # 通用混入
├── router/                 # 路由配置
│   ├── index.js
│   └── modules/            # 路由模块化
├── store/                  # Vuex 状态管理
│   ├── index.js
│   ├── getters.js
│   └── modules/            # Store 模块化
├── utils/                  # 工具函数
│   ├── request.js          # axios 封装
│   ├── auth.js             # 权限/Token
│   └── validate.js         # 校验工具
├── views/                  # 页面视图（按业务模块）
│   ├── user/
│   ├── order/
│   └── points/
├── App.vue
└── main.js
```

---

## 3. 路由架构

### 3.1 路由模式

<!-- TODO: 填写路由模式 history / hash -->

### 3.2 路由守卫

<!-- TODO: 填写全局前置守卫逻辑（权限校验、Token 刷新等） -->

### 3.3 路由模块清单

| 模块 | 路由前缀 | 对应文件 | 说明 |
|------|---------|---------|------|
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

---

## 4. 状态管理架构

### 4.1 Store 模块划分

| 模块名 | 职责 | 持久化 | 说明 |
|--------|------|--------|------|
| user | 用户信息/Token | 是 | <!-- TODO: 确认持久化方案 vuex-persistedstate / localStorage --> |
| app | 应用全局状态 | 否 | 侧边栏、主题等 |
| permission | 动态路由/权限 | 否 | <!-- TODO --> |
| <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> |

### 4.2 命名规范

-模块命名: `模块名/动作`（如 `user/setToken`、`order/setList`）
- getters 命名: `模块名 + 实体`（如 `user/token`、`order/currentOrder`）

---

## 5. HTTP 请求封装

### 5.1 请求拦截器

<!-- TODO: 填写请求拦截逻辑（Token 注入、loading 控制、重复请求取消等） -->

### 5.2 响应拦截器

<!-- TODO: 填写响应拦截逻辑（统一错误处理、401 跳转登录、业务码处理等） -->

### 5.3 接口规范

| 规范项 | 约定 |
|--------|------|
| 基路径 | <!-- TODO: 如 /api/v1 --> |
| 超时 | <!-- TODO: 如 30000ms --> |
| 请求头 | Content-Type: application/json; Authorization: Bearer {token} |
| 响应体 | 与后端 Result<T> 对齐：`{ code, message, data, timestamp }` |
| 分页参数 | <!-- TODO: 与后端对齐 { current, size } --> |

---

## 6. 权限方案

### 6.1 认证流程

<!-- TODO: 填写认证流程（登录 → Token 存储 → 刷新机制 → 退出） -->

### 6.2 路由权限

<!-- TODO: 填写路由权限方案（静态路由 + 动态路由 / 全动态路由 / 角色路由表） -->

### 6.3 按钮权限

<!-- TODO: 填写按钮级权限方案（v-permission 指令 / 权限函数 / 权限组件） -->

---

## 7. 环境配置

| 环境 | 基路径 | API 代理 | 构建命令 |
|------|--------|---------|---------|
| 开发 (dev) | <!-- TODO --> | <!-- TODO --> | `npm run dev` |
| 测试 (test) | <!-- TODO --> | <!-- TODO --> | `npm run build:test` |
| 预发 (staging) | <!-- TODO --> | <!-- TODO --> | `npm run build:staging` |
| 生产 (prod) | <!-- TODO --> | <!-- TODO --> | `npm run build:prod` |

---

## 8. 部署架构

<!-- TODO: 填写前端部署方案（Nginx / CDN / OSS 静态托管 / Docker） -->

```
<!-- TODO: 用 Mermaid 或 ASCII 画出前端部署拓扑 -->
```

---

## 9. 前后端联调约定

| 约定项 | 说明 |
|--------|------|
| API 文档 | <!-- TODO: Swagger / YApi / Apifox 地址 --> |
| Mock 方案 | <!-- TODO: 是否使用 Mock，方案是什么 --> |
| 联调环境 | <!-- TODO: 联调环境地址和部署方式 --> |
| 跨域处理 | <!-- TODO: 开发代理 / Nginx 反向代理 / CORS --> |
| 联调流程 | <!-- TODO: 前后端联调的标准流程 --> |

---

> 维护人：前端架构组
> 最后更新：2026-05-19
> 关联文档：architecture-baseline.md, frontend-standard.md
