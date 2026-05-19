# Java + Spring Cloud Alibaba 编码规范速查表

> 精简自《AI驱动研发流程-模型匹配方案.md》附录 A，作为 AI Prompt 的标准上下文
> 前端编码规范见 `frontend-standard.md`

---

## 模块结构

```
xxx-service/
├── xxx-api/                   # common-api：跨服务共享（仅 Feign + DTO + VO + 枚举）
│   └── pom.xml                # 禁止引入 spring-boot-web / mybatis-plus
└── xxx-biz/                   # 业务实现
    └── src/main/java/
        └── com/codexx/xxx/biz/
            ├── controller/    # 参数接收、权限校验、结果包装
            ├── service/impl/  # 业务逻辑、事务边界
            ├── mapper/        # 数据访问（仅 SQL 映射）
            ├── entity/        # 数据库实体
            ├── convertor/     # MapStruct 接口
            ├── vo/            # 出参视图对象
            ├── dto/           # 入参传输对象
            ├── enums/         # 私有枚举
            ├── exception/     # 自定义异常 + 全局异常处理器
            └── config/        # @Configuration
```

## 铁律（5 条必遵守）

1. Controller → Service → Mapper 严格分层，禁止跨层调用
2. Entity 禁止出现在 Controller 入参或返回值中
3. 跨服务调用必须使用 Feign，禁止 RestTemplate / HttpClient
4. Feign 必须配 FallbackFactory，禁止只配 fallback
5. `xxx-api` 模块禁止引入 spring-boot-web / mybatis-plus 等重量级依赖

## 命名规范

| 类型 | 规范 | 示例 |
|-----|------|------|
| 类名 | UpperCamelCase | `UserOrderServiceImpl` |
| 方法名 | lowerCamelCase | `getUserById` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| URL | kebab-case | `/user-orders/{order-id}` |
| 数据库表 | snake_case | `user_order` |
| 数据库字段 | snake_case | `created_at` |
| Feign 接口 | 以 FeignClient 结尾 | `OrderFeignClient` |
| FallbackFactory | 以 FallbackFactory 结尾 | `OrderFeignClientFallbackFactory` |
| common-api 模块 | 以 -api 结尾 | `order-api` |

## 依赖注入

```java
// 推荐：构造器注入（Lombok）
@RequiredArgsConstructor
@Service
public class UserServiceImpl implements IUserService {
    private final UserMapper userMapper;
    private final OrderFeignClient orderFeignClient;
}

// 禁止：字段注入 @Autowired
```

## 数据库操作

```java
// Lambda 查询（禁止硬编码字段名）
userMapper.selectList(Wrappers.<User>lambdaQuery().eq(User::getStatus, 1));

// 分页查询（必须）
Page<User> page = new Page<>(current, size);
userMapper.selectPage(page, Wrappers.<User>lambdaQuery().eq(User::getStatus, 1));

// 批量操作（500 条/批）
userMapper.insertBatchSomeColumn(userList);
```

## 日志规范

```java
log.info("[orderCreate] userId={}, amount={}, costMs={}", userId, amount, costMs);
// traceId / spanId 由 Micrometer Tracing 自动注入 MDC
```

## 统一返回体

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Result<T> {
    private Integer code;
    private String message;
    private T data;
    private Long timestamp;

    public static <T> Result<T> success(T data) { ... }
    public static <T> Result<T> fail(Integer code, String message) { ... }
}
```