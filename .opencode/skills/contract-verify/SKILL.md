---
name: contract-verify
description: Verify frontend-backend API contract alignment. Read api-spec.yaml, hit live endpoints, validate response structure with AJV. Run as a final check before archive or after frontend-backend integration.
---

# Contract Verify — 前后端契约联调验证

## 这是什么

联调阶段的"总验收"脚本：读 `api-spec.yaml` → 逐接口发真实请求 → 用 JSON Schema 校验响应结构 → 出报告。

**解决的问题**：后端按文档写了接口，前端按文档写了页面，但没人验证实际跑起来对不对齐。

## 什么时候用

- 前后端都跑起来后，联调之前
- 每次改完接口，跑一遍确认没破坏前端依赖
- Archive 之前的最终验收
- CI 阶段（可选）

## 工作流程

```
api-spec.yaml
    │
    ├─ 1. 解析 OpenAPI → 提取接口清单 + Schema
    │
    ├─ 2. 登录获取 Token（如需鉴权）
    │
    ├─ 3. 逐接口发请求（curl / node-fetch）
    │   ├─ 构造请求参数（从 spec examples 或 test fixtures）
    │   ├─ 发送请求
    │   └─ 捕获响应
    │
    ├─ 4. AJV Schema 校验
    │   ├─ 响应状态码是否匹配
    │   ├─ 响应体字段是否齐全
    │   ├─ 字段类型是否正确
    │   └─ 必填字段是否都存在
    │
    └─ 5. 输出报告
        ├─ ✅ PASS / ❌ FAIL 每个接口
        ├─ 不一致的字段详情
        └─ 前端影响评估
```

## 技术方案

### 依赖

```json
{
  "devDependencies": {
    "ajv": "^8.12.0",
    "ajv-formats": "^2.1.1",
    "yaml": "^2.3.0"
  }
}
```

### 项目目录（如不存在需手动创建 `mkdir -p tests/contract/reports`）

```
tests/contract/
├── package.json
├── contract-verify.js          # 主脚本
├── config.js                   # 环境配置（baseURL、登录凭证等）
├── fixtures/                   # 测试数据
│   ├── auth-login.json         # 登录接口的请求体
│   ├── order-create.json       # 创建订单的请求体
│   └── points-deduct.json      # 积分扣减的请求体
└── reports/                    # 输出报告
    └── contract-report-<date>.json
```

### config.js 模板

```js
module.exports = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:8080',

  // TODO: 填写鉴权配置
  auth: {
    loginUrl: '/api/v1/auth/login',
    method: 'POST',
    body: {
      // TODO: 填写测试账号
      username: '',
      password: ''
    },
    tokenPath: 'data.token'  // 响应中 token 的路径
  },

  // TODO: 填写跳过鉴权的接口（白名单）
  noAuthPaths: [
    '/api/v1/auth/login'
  ],

  // TODO: 自定义请求头
  headers: {
    'Content-Type': 'application/json'
  }
}
```

### contract-verify.js 核心逻辑

```js
const Ajv = require('ajv')
const addFormats = require('ajv-formats')
const YAML = require('yaml')
const fs = require('fs')
const path = require('path')
const http = require('http')
const https = require('https')
const config = require('./config')

const ajv = new Ajv({ strict: false })
addFormats(ajv)

// TODO: 填写 api-spec.yaml 路径
const SPEC_PATH = path.resolve(__dirname, '../../project-context/02-design/<change-name>/api-spec.yaml')

async function main() {
  console.log('📋 Contract Verify — 前后端契约联调验证\n')

  // 1. 解析 OpenAPI Spec
  const spec = YAML.parse(fs.readFileSync(SPEC_PATH, 'utf-8'))
  const paths = spec.paths || {}

  // 2. 登录获取 Token
  let token = ''
  if (config.auth.loginUrl) {
    console.log('🔑 正在登录获取 Token...')
    token = await login()
    console.log('✅ Token 获取成功\n')
  }

  // 3. 逐接口验证
  const results = []
  for (const [url, methods] of Object.entries(paths)) {
    for (const [method, operation] of Object.entries(methods)) {
      if (['get', 'post', 'put', 'patch', 'delete'].includes(method)) {
        const result = await verifyEndpoint(method.toUpperCase(), url, operation, token)
        results.push(result)
      }
    }
  }

  // 4. 输出报告
  printReport(results)

  // 5. 写入报告文件
  const reportDir = path.join(__dirname, 'reports')
  if (!fs.existsSync(reportDir)) fs.mkdirSync(reportDir, { recursive: true })
  const reportPath = path.join(reportDir, `contract-report-${new Date().toISOString().slice(0, 10)}.json`)
  fs.writeFileSync(reportPath, JSON.stringify(results, null, 2))
  console.log(`\n📄 报告已写入: ${reportPath}`)

  // 6. 有失败则退出码非零
  const failed = results.filter(r => r.status === 'FAIL')
  if (failed.length > 0) {
    console.log(`\n❌ ${failed.length} 个接口契约不匹配`)
    process.exit(1)
  }
}

async function login() {
  const res = await request({
    method: config.auth.method,
    url: config.baseUrl + config.auth.loginUrl,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config.auth.body)
  })
  const data = JSON.parse(res.body)
  return data.data.token
}

async function verifyEndpoint(method, url, operation, token) {
  const operationId = operation.operationId || `${method} ${url}`
  console.log(`🔍 验证: ${method} ${url}`)

  const result = {
    operationId,
    method,
    url,
    status: 'PASS',
    errors: [],
    warnings: []
  }

  try {
    // 构造请求
    const headers = { ...config.headers }
    if (!config.noAuthPaths.includes(url) && token) {
      headers['Authorization'] = `Bearer ${token}`
    }

    // TODO: 从 fixtures 加载请求体
    const fixturePath = path.join(__dirname, 'fixtures', `${operationId}.json`)
    let body = null
    if (fs.existsSync(fixturePath)) {
      body = JSON.stringify(JSON.parse(fs.readFileSync(fixturePath, 'utf-8')))
    } else if (method !== 'GET' && method !== 'DELETE') {
      result.warnings.push('无测试数据 fixture，跳过请求体')
    }

    // 发送请求
    const res = await request({
      method,
      url: config.baseUrl + url.replace(/{[^}]+}/g, '1'),  // 路径参数替换为 1
      headers,
      body
    })

    const statusCode = res.statusCode
    const responseBody = JSON.parse(res.body)

    // 校验状态码
    const expectedStatus = operation.responses ? Object.keys(operation.responses)[0] : '200'
    if (String(statusCode) !== expectedStatus) {
      result.errors.push(`状态码不匹配: 期望 ${expectedStatus}, 实际 ${statusCode}`)
    }

    // 校验 Result<T> 包装结构
    if (responseBody.code === undefined) {
      result.errors.push('缺少 code 字段（不符合 Result<T> 包装）')
    }
    if (responseBody.message === undefined) {
      result.errors.push('缺少 message 字段（不符合 Result<T> 包装）')
    }
    if (responseBody.data === undefined) {
      result.errors.push('缺少 data 字段（不符合 Result<T> 包装）')
    }

    // AJV Schema 校验
    const responseSchema = operation.responses?.[expectedStatus]?.content?.['application/json']?.schema
    if (responseSchema) {
      const validate = ajv.compile(responseSchema)
      const valid = validate(responseBody)
      if (!valid) {
        result.errors.push(...validate.errors.map(e =>
          `${e.instancePath} ${e.message}`
        ))
      }
    }

    // 前端影响检查：检查 data 中的字段是否为 null/undefined
    if (responseBody.data && typeof responseBody.data === 'object') {
      checkNullFields(responseBody.data, '', result.warnings)
    }

  } catch (err) {
    result.status = 'FAIL'
    result.errors.push(`请求失败: ${err.message}`)
  }

  if (result.errors.length > 0) {
    result.status = 'FAIL'
  }

  console.log(`  ${result.status === 'PASS' ? '✅' : '❌'} ${result.status}`)
  result.errors.forEach(e => console.log(`    ❌ ${e}`))
  result.warnings.forEach(w => console.log(`    ⚠️  ${w}`))

  return result
}

function checkNullFields(obj, prefix, warnings) {
  for (const [key, value] of Object.entries(obj)) {
    const path = prefix ? `${prefix}.${key}` : key
    if (value === null) {
      warnings.push(`字段 ${path} 值为 null，前端需做空值兜底`)
    } else if (value === undefined) {
      warnings.push(`字段 ${path} 值为 undefined，前端可能取值报错`)
    } else if (typeof value === 'object' && !Array.isArray(value)) {
      checkNullFields(value, path, warnings)
    }
  }
}

function request(options) {
  return new Promise((resolve, reject) => {
    const url = new URL(options.url)
    const lib = url.protocol === 'https:' ? https : http
    const reqOptions = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: options.method,
      headers: options.headers
    }
    const req = lib.request(reqOptions, (res) => {
      let body = ''
      res.on('data', chunk => body += chunk)
      res.on('end', () => resolve({ statusCode: res.statusCode, body, headers: res.headers }))
    })
    req.on('error', reject)
    req.setTimeout(10000, () => { req.destroy(); reject(new Error('请求超时')) })
    if (options.body) req.write(options.body)
    req.end()
  })
}

main().catch(err => {
  console.error('❌ 脚本异常:', err)
  process.exit(1)
})
```

## 快捷指令

| 你说 | 我做什么 |
|------|---------|
| "跑一下契约验证" | 执行 `node tests/contract/contract-verify.js` |
| "生成 fixture 数据" | 读 api-spec.yaml，为每个接口生成测试数据 JSON |
| "验证积分扣减接口" | 只验证指定接口 |
| "看上次的验证报告" | 读 `tests/contract/reports/` 最新报告 |

## 输出报告示例

```
📋 Contract Verify — 前后端契约联调验证

🔑 正在登录获取 Token...
✅ Token 获取成功

🔍 验证: POST /api/v1/points/deduct
  ✅ PASS
🔍 验证: GET /api/v1/points-accounts/{userId}
  ❌ FAIL
    ❌ 字段 data.remainingPoints 值为 null，前端需做空值兜底
    ❌ 缺少 data.pointsLevel 字段（api-spec 中定义了但响应中没有）

📊 结果汇总: 5 通过 / 2 失败 / 3 警告

❌ 2 个接口契约不匹配
```

## 和现有流程的配合

```
环节④ 标准开发（前后端代码都写完）
    ↓
环节⑤ 测试与 Debug
    ├─ 后端：单元测试 + 集成测试（dynamic-test）
    ├─ 前端：组件测试（dev-schema-guard 拦截器实时校验）
    └─ 联调：contract-verify ← 本 skill
        ↓
    契约全通过 → Archive
    契约有失败 → 修复 → 重新验证
```

## 规则

1. **前后端都跑起来才能验证**：contract-verify 是端到端验证，需要后端服务 + 数据库可用
2. **测试数据独立**：fixtures 中的数据不应依赖生产环境，用测试账号
3. **每次改接口必须重跑**：后端改了字段名/类型/必填性，跑一遍就知道前端会不会挂
4. **报告归档**：验证报告存入 `tests/contract/reports/`，Archive 时一并归档
5. **CI 集成（可选）**：可在 CI pipeline 中加入 contract-verify，每次合并前自动校验
