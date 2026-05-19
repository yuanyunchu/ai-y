-- ============================================================
-- 积分抵扣功能：数据库变更脚本
-- 变更名称：add-points-deduction
-- 版本：V1.0
-- 注意事项：请在低峰期执行，建议先在 staging 环境验证
-- ============================================================

-- ----------------------------
-- 1. 新建表：用户积分账户
-- ----------------------------
CREATE TABLE IF NOT EXISTS points_account (
    id               BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id          BIGINT NOT NULL COMMENT '用户ID',
    total_points     BIGINT NOT NULL DEFAULT 0 COMMENT '累计获得积分',
    available_points BIGINT NOT NULL DEFAULT 0 COMMENT '可用积分',
    frozen_points    BIGINT NOT NULL DEFAULT 0 COMMENT '冻结积分',
    used_points      BIGINT NOT NULL DEFAULT 0 COMMENT '已使用积分',
    expired_points   BIGINT NOT NULL DEFAULT 0 COMMENT '已过期积分',
    version          INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户积分账户';

-- ----------------------------
-- 2. 新建表：积分流水（幂等 + 对账专用）
-- ----------------------------
CREATE TABLE IF NOT EXISTS points_flow (
    id               BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id          BIGINT NOT NULL COMMENT '用户ID',
    biz_id           VARCHAR(64) NOT NULL COMMENT '业务单号（订单号）',
    biz_type         VARCHAR(32) NOT NULL COMMENT '业务类型：ORDER_DEDUCTION',
    operation_type   VARCHAR(32) NOT NULL COMMENT '操作类型：FREEZE | DEDUCT | UNFREEZE',
    points           INT NOT NULL COMMENT '本次操作积分',
    before_points    BIGINT NOT NULL DEFAULT 0 COMMENT '操作前可用积分',
    after_points     BIGINT NOT NULL DEFAULT 0 COMMENT '操作后可用积分',
    status           VARCHAR(16) NOT NULL COMMENT '积分状态：FROZEN | DEDUCTED | UNFROZEN',
    remark           VARCHAR(255) DEFAULT NULL,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_biz_operation (biz_id, biz_type, operation_type) COMMENT '幂等唯一索引',
    KEY idx_user_id_created (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='积分流水';

-- ----------------------------
-- 3. 修改表：订单表增加积分抵扣金额
-- ----------------------------
-- 适用数据库：order_db.order
-- 兼容性：默认值 0，历史订单不受影响
ALTER TABLE `order`
    ADD COLUMN `points_deduction_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00
    COMMENT '积分抵扣金额'
    AFTER `total_amount`;

-- ----------------------------
-- 4. 回滚脚本（如有需要）
-- ----------------------------
-- DROP TABLE IF EXISTS points_flow;
-- DROP TABLE IF EXISTS points_account;
-- ALTER TABLE `order` DROP COLUMN `points_deduction_amount`;