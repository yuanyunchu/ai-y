# 前端设计方案：积分抵扣（add-points-deduction）

> 变更名称：add-points-deduction
> 对应后端设计：`architecture.md`
> 对应 API 契约：`api-spec.yaml`

## 一、页面清单

| 页面 | 路由 | 权限 | 说明 |
|------|------|------|------|
| 积分账户 | `/points/account` | 已登录用户 | 查看积分余额、流水明细 |
| 积分规则管理 | `/admin/points/rules` | 管理员 | 配置积分抵扣规则 |

## 二、组件树

```
Page: /points/account
├── PointsHeader（积分数额展示）
├── PointsFilterBar（时间范围筛选）
├── PointsList（流水列表）
│   └── PointsListItem（每条流水卡片）
└── PointsPagination（分页）

Page: /admin/points/rules
├── RuleFormModal（新增/编辑规则弹窗）
├── RuleTable（规则列表）
│   └── RuleStatus（开关状态）
└── RulePagination（分页）
```

## 三、状态管理

**Vuex Store: `points.js`**

```javascript
state: {
  balance: 0,           // 当前积分余额
  transactions: [],     // 流水列表
  rules: [],            // 积分规则
  loading: false
}
```

## 四、API 对接

| 页面 | API | Method | 说明 |
|------|-----|--------|------|
| 积分账户 | `/api/v1/points/accounts/{userId}` | GET | 查询积分余额 |
| 积分账户 | `/api/v1/points/transactions?userId=&page=&size=` | GET | 分页查询流水 |
| 积分规则 | `/api/v1/points/rules` | GET | 规则列表 |
| 积分规则 | `/api/v1/points/rules` | POST | 新增规则 |

## 五、交互说明

1. 积分页面进入时自动拉取余额和最近 20 条流水
2. 流水列表支持下拉加载更多（无限滚动）
3. 规则开关切换立即生效（乐观更新 + 失败回滚）

## 六、状态说明（待细化）

<!-- TODO: 根据实际 UI 需求补充具体交互细节 -->