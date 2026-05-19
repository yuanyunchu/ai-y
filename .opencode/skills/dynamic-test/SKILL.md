---
name: dynamic-test
description: Generate and run dynamic tests for Spring Boot projects. Covers unit tests, integration tests, API contract validation, and frontend-backend coordination tools.
---

# Dynamic Test — Spring Boot 动态测试

## 这是什么

不只是看代码对不对，而是**实际跑起来**验证：
- 接口能不能通？
- 参数传对了没？
- 返回的数据格式 frontend 能不能用？
- 数据库操作有没有问题？

## 适用场景

| 场景 | 怎么做 |
|------|--------|
| 写完 Service 层 | 生成单元测试（Mock 依赖） |
| 写完 Controller | 生成接口集成测试（起真实服务测） |
| 前后端对接 | 生成 Postman 集合 / curl 命令 |
| 改完接口 | 跑契约测试，看是否破坏已有约定 |
| 前端等后端 | 生成 MockServer 响应 |

## 技术栈要求

你的项目需要这些依赖（pom.xml）：

```xml
<!-- 单元测试 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- 数据库测试（H2 内存库） -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
</dependency>

<!-- API 契约测试（可选） -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-contract-verifier</artifactId>
    <scope>test</scope>
</dependency>
```

## 怎么用

直接说你的需求：

> "帮我给 UserService 写单元测试"
> "生成登录接口的 Postman 测试"
> "跑一下积分扣减接口的契约测试"
> "前端等接口，生成 Mock 数据"

## 测试类型

### 1. 单元测试（Unit Test）

测单个类，把依赖都 Mock 掉。

**当你说：** "给 `UserService.login()` 写单元测试"

**我会生成：**

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("登录成功：返回 Token")
    void login_success() {
        // Given
        LoginRequest request = new LoginRequest("test@example.com", "password123");
        User user = User.builder()
            .id(1L)
            .email("test@example.com")
            .password("encoded_password")
            .build();

        when(userRepository.findByEmail("test@example.com"))
            .thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded_password"))
            .thenReturn(true);

        // When
        LoginResult result = userService.login(request);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getToken()).isNotBlank();
        assertThat(result.getUserId()).isEqualTo(1L);
    }

    @Test
    @DisplayName("登录失败：用户不存在")
    void login_userNotFound() {
        // Given
        LoginRequest request = new LoginRequest("notfound@example.com", "password");
        when(userRepository.findByEmail(any()))
            .thenReturn(Optional.empty());

        // When & Then
        assertThrows(UserNotFoundException.class, () -> {
            userService.login(request);
        });
    }

    @Test
    @DisplayName("登录失败：密码错误")
    void login_wrongPassword() {
        // Given
        LoginRequest request = new LoginRequest("test@example.com", "wrong");
        User user = User.builder()
            .email("test@example.com")
            .password("encoded_password")
            .build();

        when(userRepository.findByEmail(any()))
            .thenReturn(Optional.of(user));
        when(passwordEncoder.matches(any(), any()))
            .thenReturn(false);

        // When & Then
        assertThrows(BadCredentialsException.class, () -> {
            userService.login(request);
        });
    }
}
```

**放置位置：** `src/test/java/com/yourcompany/service/UserServiceTest.java`

**运行方式：**
```bash
./mvnw test -Dtest=UserServiceTest
```

### 2. 接口集成测试（Integration Test）

测整个请求链路：Controller → Service → Repository（用 H2 内存库）。

**当你说：** "给登录接口写集成测试"

**我会生成：**

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        // 准备测试数据
        User user = User.builder()
            .email("test@example.com")
            .password(passwordEncoder.encode("password123"))
            .name("Test User")
            .build();
        userRepository.save(user);
    }

    @Test
    @DisplayName("POST /api/v1/auth/login - 登录成功")
    void login_success() throws Exception {
        LoginRequest request = new LoginRequest("test@example.com", "password123");

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(200))
            .andExpect(jsonPath("$.data.token").isNotEmpty())
            .andExpect(jsonPath("$.data.user.email").value("test@example.com"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/login - 参数校验失败")
    void login_validationFailed() throws Exception {
        LoginRequest request = new LoginRequest("", "");  // 空参数

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value(400));
    }
}
```

**放置位置：** `src/test/java/com/yourcompany/controller/AuthControllerIntegrationTest.java`

**运行方式：**
```bash
./mvnw test -Dtest=AuthControllerIntegrationTest
```

### 3. API 契约测试（Contract Test）

验证接口返回是否符合文档约定。

**当你说：** "跑一下积分扣减接口的契约测试"

**我会做：**

1. 读取 `project-context/02-design/add-points-deduction/api-spec.yaml`
2. 生成契约测试：

```java
@SpringBootTest
@AutoConfigureMockMvc
class PointsDeductionContractTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("契约：扣减积分接口返回结构")
    void pointsDeduction_responseStructure() throws Exception {
        PointsDeductionRequest request = new PointsDeductionRequest(
            1001L,      // userId
            50,         // points
            "ORDER_001" // reason
        );

        mockMvc.perform(post("/api/v1/points/deduct")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isOk())
            // 验证契约：必须包含这些字段
            .andExpect(jsonPath("$.code").exists())
            .andExpect(jsonPath("$.message").exists())
            .andExpect(jsonPath("$.data.remainingPoints").exists())
            .andExpect(jsonPath("$.data.deductionId").exists())
            .andExpect(jsonPath("$.data.timestamp").exists())
            // 验证类型
            .andExpect(jsonPath("$.data.remainingPoints").isNumber())
            .andExpect(jsonPath("$.data.deductionId").isString());
    }
}
```

### 4. 前后端联调工具

#### A. 生成 curl 命令

**当你说：** "生成登录接口的 curl"

```bash
# 登录成功
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 登录失败（密码错误）
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "wrong"
  }'
```

#### B. 生成 Postman Collection

**我会生成 `postman/xxx-api.json`：**

```json
{
  "info": { "name": "积分系统 API", "schema": "https://schema.getpostman.com/json/collection/v2.1.0/" },
  "item": [
    {
      "name": "登录",
      "request": {
        "method": "POST",
        "header": [{"key": "Content-Type", "value": "application/json"}],
        "url": "{{baseUrl}}/api/v1/auth/login",
        "body": {
          "mode": "raw",
          "raw": "{\"email\": \"test@example.com\", \"password\": \"password123\"}"
        }
      }
    },
    {
      "name": "扣减积分",
      "request": {
        "method": "POST",
        "header": [
          {"key": "Content-Type", "value": "application/json"},
          {"key": "Authorization", "value": "Bearer {{token}}"}
        ],
        "url": "{{baseUrl}}/api/v1/points/deduct",
        "body": {
          "mode": "raw",
          "raw": "{\"userId\": 1001, \"points\": 50, \"reason\": \"ORDER_001\"}"
        }
      }
    }
  ],
  "variable": [
    {"key": "baseUrl", "value": "http://localhost:8080"},
    {"key": "token", "value": ""}
  ]
}
```

**前端使用方式：**
1. 打开 Postman
2. Import → 选择这个 json 文件
3. 先跑登录接口，拿到 token
4. 在 Collection 变量里填上 token
5. 跑其他接口

#### C. 生成 MockServer（前端等后端时用）

**当你说：** "前端等接口，生成 Mock"

我会生成 `src/test/resources/mock/` 下的响应文件：

```json
// mock/points/deduct/success.json
{
  "code": 200,
  "message": "success",
  "data": {
    "deductionId": "DED_20240115_001",
    "remainingPoints": 150,
    "timestamp": "2024-01-15T10:30:00Z"
  }
}

// mock/points/deduct/insufficient.json
{
  "code": 4001,
  "message": "积分不足",
  "data": {
    "required": 200,
    "available": 50
  }
}
```

配合 `mock-server.json` 配置，前端可以直接用 Mockoon / JSON Server 跑起来。

## 测试分层建议

对于 Spring Boot 项目，推荐这样的测试金字塔：

```
        /\
       /  \     E2E 测试（Selenium/Cypress）← 少量
      /____\        
     /      \   集成测试（@SpringBootTest）  ← 中等
    /________\      
   /          \ 单元测试（JUnit+Mockito）    ← 大量
  /____________\
```

| 层级 | 范围 | 速度 | 数量 |
|------|------|------|------|
| 单元测试 | 单个类 | 快（毫秒） | 多 |
| 集成测试 | Controller 层 | 中（秒） | 中 |
| 契约测试 | API 接口 | 中（秒） | 按接口数 |
| E2E 测试 | 完整流程 | 慢（分钟） | 少 |

## 目录结构规范

```
src/test/
├── java/com/yourcompany/
│   ├── unit/                    ← 单元测试
│   │   ├── service/
│   │   │   └── UserServiceTest.java
│   │   └── util/
│   │       └── DateUtilTest.java
│   ├── integration/             ← 集成测试
│   │   ├── controller/
│   │   │   └── AuthControllerTest.java
│   │   └── repository/
│   │       └── UserRepositoryTest.java
│   └── contract/                ← 契约测试
│       └── PointsDeductionContractTest.java
└── resources/
    ├── application-test.yml      ← 测试配置（H2 数据库）
    ├── data/                     ← 测试数据
    │   └── users.sql             ← 初始数据脚本
    └── mock/                     ← Mock 响应
        └── points/
            └── deduct/
                ├── success.json
                └── error.json
```

## 测试配置模板

`src/test/resources/application-test.yml`：

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    driver-class-name: org.h2.Driver
    username: sa
    password:
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
  sql:
    init:
      mode: always
      schema-locations: classpath:schema-test.sql
      data-locations: classpath:data-test.sql

# 测试时关闭安全
security:
  basic:
    enabled: false

# 日志
logging:
  level:
    com.yourcompany: DEBUG
```

## 快捷指令

| 你说 | 我做什么 |
|------|---------|
| "给 XxxService 写单元测试" | 生成 Mockito 测试，覆盖正常/异常路径 |
| "给 XxxController 写集成测试" | 生成 @SpringBootTest，起 H2 库测 |
| "跑契约测试" | 读 api-spec.yaml，验证所有接口字段 |
| "生成 Postman 集合" | 导出 json，前端直接导入 |
| "生成 curl" | 给指定接口生成测试命令 |
| "生成 Mock 数据" | 生成前端可用的假数据 |
| "测试覆盖率多少" | 跑 `mvn test jacoco:report`，看报告 |
| "所有测试跑一遍" | `mvn clean test` |

## 和现有流程的配合

```
Apply（AI 写代码）
    ↓
Quality Gate（静态检查）
    ↓
Dynamic Test（动态测试）← 新增 ✅
    ├─ 单元测试 → Mock 依赖，验证逻辑
    ├─ 集成测试 → 起服务，验证接口
    ├─ 契约测试 → 比对文档，防破坏
    └─ 联调工具 → curl/Postman/Mock
    ↓
User Review Gate（你审查）
    ↓
Git Commit
    ↓
Integration Test（流程联调验证）
```

## 规则

1. **单元测试优先**：每写一个新类，配套单元测试
2. **Controller 必测**：每个接口至少一个集成测试
3. **改接口跑契约**：改完接口先跑契约测试，看是否破坏约定
4. **测试数据独立**：用 @Transactional 或 @Sql 清理，不影响其他测试
5. **测试即文档**：好的测试用例就是接口使用示例
