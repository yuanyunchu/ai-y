# AI 需求分析：订单服务增加积分抵扣功能

> 生成模型：Kimi-k2.6 / Claude 200k（长上下文模型）
> 对应环节：① 需求与调研
> 变更名称：add-points-deduction
> 生成日期：2026-05-19

---

## 1. 业务理解

### 核心业务流程现状

```
用户下单 → 选择支付方式 → 全额支付 → 订单创建完成
```

当前系统不支持任何形式的抵扣，用户只能用现金全额支付。这在以下场景中体验不佳：
- 用户账户有大量积分但无法变现
- 大额订单（如 > 500 元）转化率偏低

### 目标业务流程

```
用户下单 → 选择抵扣积分 → 系统校验余额 → 冻结积分 → 支付差额 → 扣减积分
```

---

## 2. 服务边界分析

| 服务 | 当前职责 | 变更后职责 | 边界合理性 |
|------|---------|-----------|-----------|
| **user-service** | 用户 CRUD | 增加：积分账户管理 | ✅ 合理 — 积分是用户属性的一部分 |
| **order-service** | 订单 CRUD | 增加：积分抵扣参数校验、金额重算 | ✅ 合理 — 抵扣逻辑与订单耦合 |
| **payment-service** | 支付处理 | 增加：抵扣后金额计算 | ✅ 合理 — 支付金额是支付服务的核心 |

**结论**：无需新建服务，在现有边界内扩展即可。

---

## 3. 影响面分析

### 代码层面

```
user-service/
├── controller/
│   └── PointsController.java          [NEW]
├── service/
│   ├── IPointsAccountService.java     [NEW]
│   └── impl/PointsAccountServiceImpl.java [NEW]
├── mapper/
│   ├── PointsAccountMapper.java       [NEW]
│   └── PointsFlowMapper.java          [NEW]
├── entity/
│   ├── PointsAccount.java             [NEW]
│   └── PointsFlow.java                [NEW]
└── enums/
    └── PointsStatus.java              [NEW]

order-service/
├── controller/
│   └── OrderController.java           [MODIFIED: 增加 pointsDeduction 参数]
├── service/impl/
│   └── OrderServiceImpl.java          [MODIFIED: 增加积分校验和冻结调用]
├── entity/
│   └── Order.java                     [MODIFIED: 增加 pointsDeductionAmount 字段]
└── dto/
    └── CreateOrderDTO.java            [MODIFIED: 增加 PointsDeductionDTO]

common-api/
├── feign/
│   ├── PointsFeignClient.java         [NEW]
│   └── PointsFeignClientFallbackFactory.java [NEW]
├── dto/
│   └── PointsDeductionDTO.java        [NEW]
└── vo/
    └── PointsAccountVO.java           [NEW]
```

### 数据库层面

| 变更类型 | 表名 | 说明 |
|---------|------|------|
| NEW | `points_account` | 用户积分账户（user_id, available_points, frozen_points） |
| NEW | `points_flow` | 积分流水（biz_id, biz_type, operation_type, points, status） |
| MODIFIED | `order` | 增加 `points_deduction_amount` DECIMAL(10,2) |

---

## 4. 接口梳理

### 新增 Feign 接口（user-service → common-api）

| 接口 | 方法 | 说明 | 幂等性 |
|------|------|------|--------|
| `/points/accounts/{userId}` | GET | 查询积分余额 | ✅ 天然幂等 |
| `/points/freeze` | POST | 冻结积分 | ✅ 业务单号幂等 |
| `/points/deduct` | POST | 扣减积分 | ✅ 业务单号幂等 |
| `/points/unfreeze` | POST | 解冻积分 | ✅ 业务单号幂等 |

### 修改的 HTTP 接口

| 接口 | 方法 | 变更内容 |
|------|------|---------|
| `POST /orders` | POST | 入参增加 `pointsDeduction` 字段 |
| `POST /payments/notify` | POST | 回调处理增加积分抵扣订单识别 |

---

## 5. 技术债扫描

| 问题 | 严重度 | 建议 |
|------|--------|------|
| `order-service` 的 `OrderServiceImpl` 方法体超过 300 行 | 中 | 本次改造时抽取专用 `PointsDeductionService` |
| `Order` 实体缺少 version 乐观锁字段 | 低 | 本次一并添加 version 字段 |
| `OrderController` 中直接操作 Map 接收参数 | 低 | 统一使用 DTO + @Valid 校验 |

---

## 6. 待澄清问题清单（交产品经理）

1. 积分汇率是否固定（100:1），还是需要支持活动期间浮动？
2. 积分抵扣是否有最低消费金额限制？（如满 10 元才能抵扣）
3. 积分是否需要有效期？过期积分自动清零还是发送提醒？
4. 退货场景：已抵扣的积分是否原路返回？
5. 是否需要积分抵扣的每日限额？