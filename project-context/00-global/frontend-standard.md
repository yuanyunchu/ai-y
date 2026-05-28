# Vue 2 前端编码规范速查表

> 精简版，作为 AI Prompt 的标准上下文
> 详细架构见 `frontend-architecture.md`
> 未明确的项目定制点必须先确认后再生成代码，禁止让 AI 猜测 UI 库、构建工具或样式方案

---

## 技术栈

| 项 | 值 |
|----|-----|
| 框架 | Vue 2.x |
| UI 库 | 以 `frontend-architecture.md` 为准；未配置时先确认 |
| 状态管理 | Vuex 3.x |
| 路由 | Vue Router 3.x |
| HTTP | 以项目 `src/utils/request` 或同等封装为准；未配置时先确认 |
| CSS | 以项目现有样式方案为准；未配置时先确认 |
| 构建 | 以项目 `package.json` scripts 为准；未配置时先确认 |

---

## 铁律（6 条必遵守）

1. **组件命名**：多词命名，禁止与 HTML 元素冲突（`UserList` ✅ / `List` ❌）
2. **Props 必须定义类型**：禁止无类型 Props，复杂对象用 `Object` + `validator`
3. **禁止直接操作 DOM**：必须通过 `ref` 或 Vue 数据驱动，禁止 jQuery 操作
4. **Vuex 异步操作放 Action**：`mutation` 必须是同步函数，API 调用放 `action`
5. **v-for 必须加 :key**：且禁止用 `index` 作为 key（列表会重新排序时）
6. **组件销毁必须清理副作用**：`setTimeout` / `setInterval` / `EventBus.$on` 必须在 `beforeDestroy` 中清除

---

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 组件文件名 | PascalCase 或 kebab-case | `UserList.vue` / `user-list.vue` |
| 组件 name | PascalCase | `UserList` |
| Props / Data | camelCase | `userName`, `orderList` |
| 事件名 | kebab-case | `@item-click`, `@form-submit` |
| Vuex 模块 | camelCase | `user`, `orderList` |
| Vuex mutation | UPPER_SNAKE_CASE | `SET_TOKEN`, `ADD_ORDER` |
| Vuex action | camelCase | `fetchUserList`, `submitOrder` |
| CSS class | kebab-case / BEM | `user-list`, `user-list__item--active` |
| 路由 path | kebab-case | `/user-orders`, `/points-account` |
| API 文件 | kebab-case | `user-api.js`, `order-api.js` |

---

## 组件规范

### 单文件组件结构顺序

```vue
<template>
  <!-- 模板中只放结构和组件组合，业务逻辑放在 script methods/computed 中 -->
</template>

<script>
// 1. 依赖导入
// 2. mixins
// 3. Props（必须定义类型和默认值）
// 4. Data（函数返回）
// 5. Computed
// 6. Watch
// 7. 生命周期钩子（按执行顺序）
// 8. Methods
</script>

<style scoped lang="scss">
/* 必须加 scoped，禁止全局样式污染 */
</style>
```

### 组件粒度

| 粒度 | 职责 | 示例 |
|------|------|------|
| 页面组件 | 路由级，负责数据获取和布局 | `views/order/List.vue` |
| 业务组件 | 可复用的业务逻辑 | `components/business/OrderCard.vue` |
| 基础组件 | 无业务逻辑，纯 UI | `components/common/SearchInput.vue` |

---

## Vuex 规范

```js
// store/modules/order.js
const state = {
  list: [],
  current: null,
  total: 0
}

const getters = {
  orderList: state => state.list,
  currentOrder: state => state.current
}

const mutations = {
  SET_LIST: (state, list) => { state.list = list },
  SET_CURRENT: (state, order) => { state.current = order },
  SET_TOTAL: (state, total) => { state.total = total }
}

const actions = {
  async fetchOrderList({ commit }, params) {
    const { data } = await getOrderList(params)
    commit('SET_LIST', data.records)
    commit('SET_TOTAL', data.total)
    return data
  }
}
```

---

## API 请求规范

```js
// api/order.js
import request from '@/utils/request'

export function getOrderList(params) {
  return request({
    url: '/api/v1/orders',
    method: 'get',
    params
  })
}

export function createOrder(data) {
  return request({
    url: '/api/v1/orders',
    method: 'post',
    data
  })
}
```

**规则**：
- 每个 API 函数只做一件事，禁止一个函数处理多种请求
- 返回 Promise，调用方用 `async/await`
- 错误处理统一在拦截器，业务层只处理业务逻辑

---

## 样式规范

默认复用项目现有样式体系；未确认预处理器和变量路径前，不新增样式依赖。

| 规范项 | 约定 |
|--------|------|
| 命名方案 | 默认 kebab-case / BEM；若项目已有 CSS Modules 或其他方案，以项目现状为准 |
| 预处理器 | 以项目现有配置为准；未配置时先确认，不新增依赖 |
| 全局变量 | 优先复用项目已有颜色、字号、间距变量；未找到时先确认 |
| 深度选择器 | Vue 2 使用 `::v-deep` 或 `/deep/`，禁止用 `>>>` |
| 禁止 | `!important`（除非覆盖第三方组件且无其他方案） |

---

## 路由规范

```js
// router/modules/order.js
export default [
  {
    path: '/orders',
    name: 'OrderList',
    component: () => import('@/views/order/List.vue'),
    meta: {
      title: '订单列表',
      // 其他 meta 字段以现有路由约定为准，如 keepAlive、权限标识等
    }
  }
]
```

**规则**：
- 路由懒加载：`() => import('@/views/xxx.vue')`
- 路由 name 必须唯一，与组件 name 一致
- meta 中必须定义 `title`

---

## 表单与校验

表单校验方案以项目 UI 库和现有封装为准；未明确时先确认，禁止直接引入新校验库。

```js
// 示例：Element-UI 表单校验
rules: {
  userName: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 2, max: 20, message: '长度 2-20 个字符', trigger: 'blur' }
  ]
}
```

---

## 常见模式

### 列表页模式

```vue
<!-- 列表页默认包含搜索、重置、表格、分页、loading、空状态和错误提示；具体组件以项目 UI 库为准。 -->
```

### 表单页模式

```vue
<!-- 表单页默认支持新增/编辑复用、提交前校验、提交中防重复点击、提交成功返回或刷新列表。 -->
```

### 详情页模式

```vue
<!-- 详情页默认支持只读展示、加载态、空态、错误态和返回入口；复杂详情按模块拆分业务组件。 -->
```

---

## 禁止项

| 禁止 | 替代方案 |
|------|---------|
| `v-html`（XSS 风险） | 纯文本 `{{ }}` 或 DOMPurify 过滤 |
| `$parent` / `$children` | Props / Events / Vuex |
| `EventBus`（除非简单场景） | Vuex / Props-Events |
| 在 `created` / `mounted` 中写复杂逻辑 | 抽到 methods 或 action |
| 内联样式 `style="..."` | class + CSS |
| 硬编码后端地址 | 环境变量 `.env` |

---

> 维护人：前端架构组
> 最后更新：2026-05-19
> 关联文档：frontend-architecture.md, coding-standard.md
