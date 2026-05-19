## Context

### 当前系统状态
- 订单支付链路：`order-service` → `payment-service`（Seata AT 分布式事务）
- 用户服务现状：仅提供用户基本信息查询，无积分体系
- 支付服务现状：按订单全额金额发起支付，无抵扣概念

### 技术栈约束
- Java 17 + Spring Boot 3.x + Spring Cloud Alibaba 2022.x
- ORM：MyBatis-Plus（唯一选择）
- 分布式事务：Seata AT 模式
- 缓存：Redis + Caffeine
- 限流：Sentinel
- 链路追踪：Micrometer Tracing + Zipkin

## Goals / Non-Goals

**Goals:**
1. 支持订单创建时传入积分抵扣参数，按 100 积分 = 1 元汇率折算
2. 保证积分操作的数据一致性（不超卖、不丢失）
3. 实现完整的积分状态机（可用 → 冻结 → 扣减/解冻）
4. 保证积分冻结、扣减、解冻操作的幂等性
5. 单订单积分抵扣金额不超过订单总金额的 50%

**Non-Goals:**
1. 不实现积分获取/赚取逻辑（本次仅涉及消费侧）
2. 不实现积分兑换商品功能
3. 不实现多币种积分汇率
4. 不实现积分过期提醒（仅记录过期时间）

## Decisions

### Decision 1: 积分状态机设计
**选择**：采用三状态机（AVAILABLE → FROZEN → DEDUCTED/UNFROZEN）
**理由**：
- 冻结态是支付链路的核心：订单创建即冻结，支付成功才扣减，失败/取消则解冻
- 避免直接扣减后支付失败导致的积分回滚复杂性
- 状态变更通过数据库乐观锁（version 字段）保证并发安全

### Decision 2: 分布式事务方案
**选择**：Seata AT 模式，事务发起方设在 `order-service`
**理由**：
- 已有基础设施，团队熟悉 AT 模式
- 链路仅 3 个服务（order → user → payment），事务边界可控
- 事务总耗时预估 < 2s（满足 Seata AT 长事务规避原则）

**事务边界**：
```
@GlobalTransactional
order-service: 创建订单 + 调用 user-service 冻结积分
  ├─ user-service: 冻结积分（本地事务）
  └─ payment-service: 创建支付单（本地事务）
```

### Decision 3: 幂等性方案
**选择**：数据库唯一索引（`biz_id` + `biz_type` + `operation_type`）
**理由**：
- 积分操作天然有业务单号（订单号）作为幂等键
- 比 Redis Token 方案更可靠（不依赖缓存）
- 结合 MyBatis-Plus `saveOrUpdate` 实现简单

**唯一索引**：`uk_points_flow_biz` ON `points_flow` (`biz_id`, `biz_type`, `operation_type`)

### Decision 4: 并发控制
**选择**：Redis 分布式锁（Redisson）+ 数据库乐观锁（version）
**理由**：
- Redis 锁防止同一用户并发操作积分（如同时下两单）
- 乐观锁作为兜底，防止数据库层面并发更新丢失
- 锁粒度：用户级（`lock:points:{userId}`），最小化锁范围

### Decision 5: 汇率存储
**选择**：Nacos 配置中心管理积分汇率（默认 100:1）
**理由**：
- 汇率可能随运营活动调整，需动态变更
- Nacos 热更新能力满足需求，无需发版

## Risks / Trade-offs

| 风险 | 等级 | 应对策略 |
|------|------|---------|
| **积分超卖** | 高 | Redis 分布式锁（用户级）+ 数据库乐观锁双重防护；冻结时校验余额 |
| **分布式事务超时** | 中 | Seata 超时设 30s；事务内只包含必要操作；监控告警 |
| **幂等失效导致重复扣减** | 高 | 唯一索引兜底；所有积分操作记录流水；对账任务每日扫描 |
| **高并发下 Redis 锁热点** | 中 | 锁粒度为用户级，非全局锁；监控 Redis 延迟；必要时本地缓存 + 定时同步 |
| **历史订单兼容性** | 低 | `points_deduction_amount` 字段默认 0；旧订单查询逻辑兼容 |
| **积分流水数据膨胀** | 中 | 流水表按用户 ID 分表（预留扩展点）；冷热数据分离（6 个月后归档） |

**Trade-off**：
- 选择冻结态而非直接扣减：增加一次状态变更，但显著提升资金安全性和回滚简单性
- 选择数据库唯一索引而非 Redis Token：牺牲了部分性能（唯一索引冲突抛异常需捕获），但获得更高可靠性