# Vue 2 前端编码规范速查表

> 精简版，作为 AI Prompt 的标准上下文
> 详细架构见 `frontend-architecture.md`
> **TODO 标记为项目定制点**，接入新项目时需按照实际 UI 库/构建工具填写

---

## 技术栈

| 项 | 值 |
|----|-----|
| 框架 | Vue 2.x |
| UI 库 | <!-- TODO: Element-UI / Ant Design Vue 等 --> |
| 状态管理 | Vuex 3.x |
| 路由 | Vue Router 3.x |
| HTTP | <!-- TODO: axios 等 --> |
| CSS | <!-- TODO: SCSS / Less --> |
| 构建 | <!-- TODO: webpack / vite --> |

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
  <!-- TODO: 填写团队偏好的组件结构顺序 -->
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

<!-- TODO: 填写团队样式规范 -->

| 规范项 | 约定 |
|--------|------|
| 命名方案 | <!-- TODO: BEM / kebab-case / CSS Modules / Scoped --> |
| 预处理器 | <!-- TODO: SCSS 变量 / mixin 定义位置 --> |
| 全局变量 | <!-- TODO: 颜色、字号、间距变量文件路径 --> |
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
      <!-- TODO: 填写其他 meta 约定，如 keepAlive、权限标识等 -->
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

<!-- TODO: 填写表单校验方案（Element-UI 自带 / async-validator / 自定义） -->

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
<!-- TODO: 填写团队标准列表页模式（搜索 + 表格 + 分页） -->
```

### 表单页模式

```vue
<!-- TODO: 填写团队标准表单页模式（新增/编辑复用） -->
```

### 详情页模式

```vue
<!-- TODO: 填写团队标准详情页模式 -->
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
