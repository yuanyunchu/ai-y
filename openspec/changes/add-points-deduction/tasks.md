## 1. Infrastructure & Data Layer

- [ ] 1.1 创建 `points_account` 表（用户积分账户）
- [ ] 1.2 创建 `points_flow` 表（积分流水，用于幂等和对账）
- [ ] 1.3 `order` 表增加 `points_deduction_amount` 字段（默认 0）
- [ ] 1.4 Nacos 增加积分汇率配置 `points.exchange.rate=100`
- [ ] 1.5 user-service 增加 Sentinel 限流规则（积分接口 QPS 限流 200）

## 2. common-api（跨服务共享模块）

- [ ] 2.1 创建 `PointsDeductionDTO`（订单创建积分抵扣入参）
- [ ] 2.2 创建 `PointsAccountVO`（积分账户余额出参）
- [ ] 2.3 创建 `PointsFlowVO`（积分流水出参）
- [ ] 2.4 创建 `PointsFeignClient` + `PointsFeignClientFallbackFactory`
- [ ] 2.5 更新 `order-service` 的 `CreateOrderDTO`（增加 `pointsDeduction` 字段）

## 3. user-service（核心积分服务）

- [ ] 3.1 实现 `PointsAccountService`：查询可用余额、冻结、扣减、解冻
- [ ] 3.2 实现积分状态机流转逻辑（AVAILABLE → FROZEN → DEDUCTED/UNFROZEN）
- [ ] 3.3 实现 Redis 分布式锁（Redisson）防护并发扣减
- [ ] 3.4 实现幂等控制（基于 `points_flow` 唯一索引）
- [ ] 3.5 实现 `PointsController`：暴露 4 个内部 Feign 接口
- [ ] 3.6 编写核心逻辑单元测试（覆盖率 ≥ 80%）

## 4. order-service（订单服务改造）

- [ ] 4.1 改造 `OrderService.createOrder()`：增加积分抵扣参数校验和金额计算
- [ ] 4.2 集成 `PointsFeignClient` 调用冻结积分（在 `@GlobalTransactional` 内）
- [ ] 4.3 改造订单金额计算逻辑：`finalAmount = totalAmount - pointsDeductionAmount`
- [ ] 4.4 实现订单超时自动取消任务（解冻积分）
- [ ] 4.5 改造 `OrderController`：接收 `pointsDeduction` 参数

## 5. payment-service（支付服务适配）

- [ ] 5.1 改造支付金额计算：实际支付金额扣除积分抵扣部分
- [ ] 5.2 改造支付回调处理：识别积分抵扣订单，触发积分扣减
- [ ] 5.3 回调幂等性校验（基于支付平台流水号）

## 6. Testing & Observability

- [ ] 6.1 编写积分状态机单元测试（状态流转全覆盖）
- [ ] 6.2 编写并发扣减压力测试（JMeter / k6，100 并发用户）
- [ ] 6.3 编写分布式事务回滚集成测试
- [ ] 6.4 配置关键指标监控（积分冻结/扣减/解冻 QPS、失败率、延迟 P99）
- [ ] 6.5 关键路径增加结构化日志（trace_id, user_id, order_id, points, operation）

## 7. Documentation & Archive

- [ ] 7.1 更新 `project-context/00-global/architecture-baseline.md`（新增积分服务接口）
- [ ] 7.2 编写接口文档（Swagger/OpenAPI）
- [ ] 7.3 完成 OpenSpec Archive，同步 specs 到 `openspec/specs/`
- [ ] 7.4 编写上线 Checklist（配置变更、数据库迁移、监控确认）