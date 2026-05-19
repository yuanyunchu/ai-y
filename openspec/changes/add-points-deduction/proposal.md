## Why

当前订单支付流程仅支持全额现金支付，缺乏用户留存手段。竞品（如淘宝、京东）已普遍支持积分抵扣功能，可显著提升用户复购率和平台粘性。根据产品部 Q2 规划，需在 6 月底前上线积分抵扣 MVP 版本。

核心问题：
1. 用户积分资产无法变现，积分体系活跃度低（当前月活使用率 < 5%）
2. 大额订单转化率低，缺少价格敏感型用户的支付激励
3. 现有支付链路无预留扩展点，需零侵入式接入

## What Changes

1. **新增积分抵扣能力**：订单创建时支持传入 `pointsDeduction` 参数，按汇率折算抵扣订单金额
2. **新增积分账户服务接口**：`user-service` 暴露积分查询、冻结、扣减、解冻 4 个 Feign 接口
3. **订单服务改造**：`order-service` 创建订单接口增加积分抵扣参数校验和金额重算逻辑
4. **支付服务适配**：`payment-service` 实际支付金额 = 订单金额 - 积分抵扣金额
5. **数据层变更**：`user-service` 新增 `points_account` 表；`order-service` 订单表增加 `points_deduction_amount` 字段

## Capabilities

### New Capabilities
- `points-deduction`: 订单支付时支持使用用户积分按固定汇率抵扣部分订单金额，涉及积分冻结、扣减、解冻状态机管理
- `points-account-query`: 查询用户当前可用积分余额及冻结积分明细

### Modified Capabilities
- `order-creation`: 创建订单接口增加 `pointsDeduction` 入参，增加积分可用性校验、抵扣金额计算、与支付金额联动逻辑
- `payment-processing`: 支付回调处理需识别积分抵扣订单，更新订单实际支付金额

## Impact

| 服务 | 影响类型 | 具体影响 |
|------|---------|---------|
| `order-service` | 接口变更 + 逻辑新增 | `POST /orders` 增加字段；新增积分抵扣计算逻辑；Seata 事务边界扩大 |
| `user-service` | 新模块 + 新接口 | 新增 `points_account` 表；新增 4 个 Feign 接口；需配置 Sentinel 限流 |
| `payment-service` | 逻辑适配 | 支付金额计算逻辑调整；回调处理增加积分抵扣标记 |
| `common-api` | 新增 DTO/VO/Feign | 新增 `PointsDeductionDTO`、`PointsAccountVO`、`PointsFeignClient` |
| Gateway | 路由不变 | 无需变更，但需关注积分接口的限流策略 |
| Nacos | 配置新增 | `user-service` 需注册新限流规则配置 |

**数据影响**：
- 新增表：`points_account`（用户积分账户）、`points_flow`（积分流水，用于对账）
- 改表：`order` 表增加 `points_deduction_amount` DECIMAL(10,2) 字段（默认 0，兼容历史订单）

**非功能影响**：
- 分布式事务复杂度上升：订单创建链路从 2 个服务 → 3 个服务
- 需新增幂等控制：积分冻结/扣减操作必须幂等
- 并发风险：高并发场景下积分超卖需 Redis 分布式锁防护