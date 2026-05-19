---
name: dev-schema-guard
description: Axios response interceptor that validates API response schema in development mode. Shows console errors and optional on-screen warnings when backend response doesn't match expected structure. Catches field mismatches in real-time during frontend development.
---

# Dev Schema Guard — 前端开发实时 Schema 校验

## 这是什么

在 axios 响应拦截器中加入 JSON Schema 校验，**开发阶段实时报错**：后端返回的字段和前端期望的对不齐，立即在控制台和页面上红屏提示。

**解决的问题**：前端按文档写了页面，后端改了字段没说，到联调才发现页面白屏或数据不显示。

## 什么时候用

- 前端开发阶段（仅 dev 环境生效）
- 前后端并行开发时，前端接后端接口
- 每次对接新接口时

## 工作模式

```
前端发请求
    ↓
axios 响应拦截器
    ↓
开发环境？
    ├─ 否 → 直接返回，不做校验
    └─ 是 → 查找该接口的 Schema 定义
              ↓
         Schema 存在？
              ├─ 否 → 跳过（未配置的接口不校验）
              └─ 是 → AJV 校验 res.data
                        ↓
                   校验通过？
                        ├─ 是 → 正常返回
                        └─ 否 → console.error 报错
                               + 页面右上角红色警告浮层
```

## 技术方案

### 依赖

```json
{
  "devDependencies": {
    "ajv": "^8.12.0",
    "ajv-formats": "^2.1.1"
  }
}
```

### 项目目录

```
src/
├── utils/
│   ├── request.js              # axios 封装（已存在，需修改）
│   └── schema-guard/           # 新增
│       ├── index.js            # 拦截器注册
│       ├── schemas.js          # 接口 Schema 注册表
│       └── overlay.js          # 页面浮层提示
├── api/
│   └── ...                     # 接口定义
└── ...
```

### schemas.js — 接口 Schema 注册表

```js
// TODO: 按接口逐个填写 Schema，从 api-spec.yaml 中提取
// 建议每次对接新接口时，同步在这里添加对应的响应 Schema

const schemas = {
  // 示例：登录接口
  'POST /api/v1/auth/login': {
    type: 'object',
    required: ['code', 'message', 'data'],
    properties: {
      code: { type: 'integer' },
      message: { type: 'string' },
      data: {
        type: 'object',
        required: ['token', 'user'],
        properties: {
          token: { type: 'string' },
          user: {
            type: 'object',
            required: ['id', 'email', 'name'],
            properties: {
              id: { type: 'integer' },
              email: { type: 'string', format: 'email' },
              name: { type: 'string' },
              phone: { type: ['string', 'null'] },
              avatar: { type: ['string', 'null'] }
            }
          }
        }
      },
      timestamp: { type: 'integer' }
    }
  }

  // TODO: 添加更多接口 Schema
  // 'GET /api/v1/orders': { ... },
  // 'POST /api/v1/orders': { ... },
  // 'GET /api/v1/points-accounts/{userId}': { ... },
}

export default schemas
```

### index.js — 拦截器核心

```js
import Ajv from 'ajv'
import addFormats from 'ajv-formats'
import schemas from './schemas'
import { showErrorOverlay, hideErrorOverlay } from './overlay'

const ajv = new Ajv({ strict: false, allErrors: true })
addFormats(ajv)

const isDev = process.env.NODE_ENV === 'development'

export function setupSchemaGuard(axiosInstance) {
  if (!isDev) return

  axiosInstance.interceptors.response.use(
    (response) => {
      validateResponse(response)
      return response
    },
    (error) => {
      if (error.response) {
        validateResponse(error.response)
      }
      return Promise.reject(error)
    }
  )
}

function validateResponse(response) {
  const key = `${response.config.method.toUpperCase()} ${response.config.url}`
  
  // 模糊匹配：处理路径参数（如 /api/v1/orders/123 → /api/v1/orders/{id}）
  const schema = findSchema(key)
  if (!schema) return

  const validate = ajv.compile(schema)
  const valid = validate(response.data)

  if (!valid) {
    const errors = validate.errors.map(e => 
      `  ${e.instancePath || '/'} ${e.message}`
    ).join('\n')

    console.error(
      `%c[Schema Guard] ${key}\n` +
      `%c响应结构不匹配:\n${errors}`,
      'color: red; font-weight: bold; font-size: 14px;',
      'color: red; font-size: 12px;'
    )
    console.log('[Schema Guard] 实际响应:', response.data)

    showErrorOverlay(key, validate.errors)
  } else {
    hideErrorOverlay()
  }
}

function findSchema(key) {
  if (schemas[key]) return schemas[key]

  // 模糊匹配路径参数
  for (const schemaKey of Object.keys(schemas)) {
    const pattern = schemaKey
      .replace(/\{[^}]+\}/g, '[^/]+')
      .replace(/\//g, '\\/')
    const regex = new RegExp(`^${key.split(' ')[0]} ${pattern}$`)
    if (regex.test(key)) return schemas[schemaKey]
  }

  return null
}
```

### overlay.js — 页面浮层提示

```js
let overlayEl = null
let timer = null

export function showErrorOverlay(apiKey, errors) {
  if (!overlayEl) {
    overlayEl = document.createElement('div')
    overlayEl.id = 'schema-guard-overlay'
    document.body.appendChild(overlayEl)
  }

  const errorList = errors.slice(0, 5).map(e =>
    `<div style="margin: 4px 0;">• ${e.instancePath || '/'} ${e.message}</div>`
  ).join('')

  overlayEl.innerHTML = `
    <div style="
      position: fixed; top: 12px; right: 12px; z-index: 99999;
      background: #fff0f0; border: 2px solid #ff4d4f; border-radius: 8px;
      padding: 12px 16px; max-width: 420px; font-size: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      font-family: monospace;
    ">
      <div style="font-weight: bold; color: #ff4d4f; margin-bottom: 8px;">
        ⚠ Schema Guard: 接口响应不匹配
      </div>
      <div style="color: #333; margin-bottom: 4px;">${apiKey}</div>
      <div style="color: #ff4d4f;">${errorList}</div>
      <div style="color: #999; margin-top: 8px; font-size: 11px;">
        仅开发环境显示，请检查后端接口是否变更
      </div>
    </div>
  `

  clearTimeout(timer)
  timer = setTimeout(hideErrorOverlay, 8000)
}

export function hideErrorOverlay() {
  if (overlayEl) {
    overlayEl.innerHTML = ''
  }
}
```

### 在 request.js 中注册

```js
// src/utils/request.js — 在现有 axios 封装中加一行

import axios from 'axios'
import { setupSchemaGuard } from './schema-guard'

const service = axios.create({
  baseURL: process.env.VUE_APP_BASE_API,
  timeout: 30000
})

// ... 现有的请求拦截器、响应拦截器 ...

// 开发环境 Schema 校验（加在最后）
setupSchemaGuard(service)

export default service
```

## 和现有流程的配合

```
环节④ 标准开发（前端写页面）
    ↓
前端开发时，每个接口请求都被 Schema Guard 实时校验
    ├─ 字段对齐 → 正常开发，无感知
    └─ 字段不对齐 → 控制台红字 + 页面右上角浮层
                    ↓
              立即修复（不用等联调才发现）
    ↓
环节⑤ 联调
    ├─ dev-schema-guard：开发时实时兜底 ← 本 skill
    └─ contract-verify：联调时总验收 ← 配合使用
```

## 快捷指令

| 你说 | 我做什么 |
|------|---------|
| "给登录接口加 Schema 校验" | 在 schemas.js 中添加该接口的响应 Schema |
| "从 api-spec 生成所有 Schema" | 读 api-spec.yaml，批量生成 schemas.js 条目 |
| "关掉 Schema Guard" | 临时设置 `isDev = false` 或注释掉 `setupSchemaGuard` |
| "Schema Guard 报错了" | 分析报错，判断是后端改了还是 Schema 过期 |

## 规则

1. **仅开发环境生效**：`process.env.NODE_ENV === 'development'` 才注册拦截器，生产环境不打包
2. **Schema 必须与 api-spec.yaml 同步**：后端改接口时，同步更新 schemas.js
3. **不阻塞业务**：校验失败只报警，不阻断请求返回，页面仍正常渲染（可能数据缺失）
4. **渐进式添加**：不需要一次配齐所有接口，优先配核心接口和频繁变更的接口
5. **浮层 8 秒自动消失**：避免影响开发体验，控制台日志保留
