# qc_app_flow_network

> **QcAppFlow 框架的网络层插件** — 基于 [Dio 5.x](https://pub.dev/packages/dio) 封装，提供统一、简洁、可扩展的 HTTP 请求能力。

---

## ✨ 特性一览

| 功能 | 说明 |
|------|------|
| 🔧 **统一配置** | `QcHttpConfig` 集中管理 baseUrl、超时、请求头等 |
| 🌐 **标准请求方法** | GET / POST / PUT / DELETE，支持文件上传和下载 |
| 🔒 **认证拦截器** | `QcAuthInterceptor` 自动注入 Token，支持 Token 刷新重试 |
| ✍️ **签名拦截器** | `QcSignInterceptor` 参数签名框架，支持注入到 Header 或 Query |
| 📋 **日志拦截器** | `QcLogInterceptor` 请求+响应合并输出，自动统计耗时，支持截断 |
| 💥 **统一异常** | `QcHttpException` + `QcExceptionType` 精细分类所有错误类型 |
| 🔄 **数据转换器** | `QcConverter<T>` 支持自定义响应数据映射 |
| ❌ **请求取消** | `QcCancelToken` 安全包装 Dio 的取消机制 |
| 📦 **响应封装** | `QcResponse<T>` 统一响应格式，携带状态码、数据和头信息 |

---

## 📦 安装

在你的 `pubspec.yaml` 中引用本插件（本地路径方式）：

```yaml
dependencies:
  qc_app_flow_network:
    path: ../plugin/qc_app_flow_network
```

然后在 Dart 代码顶部导入：

```dart
import 'package:qc_app_flow_network/qc_app_flow_network.dart';
```

---

## 🏗️ 架构总览

```
qc_app_flow_network
├── QcHttp                  ← 核心 HTTP 客户端（基于 Dio）
├── QcHttpConfig            ← 全局配置（baseUrl / 超时 / 请求头）
├── QcResponse<T>           ← 统一响应体
├── QcRequestOptions        ← 单次请求参数配置
├── QcConverter<T>          ← 响应数据转换器接口
├── QcCancelToken           ← 请求取消工具
├── QcHttpException         ← 统一网络异常
├── QcExceptionType         ← 异常类型枚举
├── QcAuthInterceptor       ← 抽象认证拦截器（Token注入 + 自动刷新）
├── QcSignInterceptor       ← 抽象签名拦截器（参数签名框架）
└── QcLogInterceptor        ← 日志拦截器（请求耗时合并输出）
```

---

## 🚀 快速开始

### 1. 创建 `QcHttp` 实例

```dart
final http = QcHttp(
  config: QcHttpConfig(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept-Language': 'zh-CN'},
    enableLog: true,  // 开启日志
  ),
);
```

### 2. 发起基础请求

```dart
// GET 请求
final res = await http.get<Map<String, dynamic>>(
  '/user/profile',
  queryParameters: {'userId': '123'},
);
print(res.data); // 响应数据

// POST 请求
final res = await http.post<Map<String, dynamic>>(
  '/order/create',
  data: {'productId': 'p001', 'qty': 2},
);
```

### 3. 处理异常

```dart
try {
  final res = await http.get('/some/api');
} on QcHttpException catch (e) {
  if (e.isUnauthorized) {
    // Token 失效，跳转登录
  } else if (e.isTimeoutError) {
    // 超时，提示用户
  } else if (e.isBusinessError) {
    // 业务错误，显示 e.message
    print('业务错误: ${e.message} (code: ${e.code})');
  }
}
```

---

## 📖 核心 API 详解

### `QcHttp` — HTTP 客户端

| 方法 | 说明 |
|------|------|
| `get<T>(path, {...})` | 发起 GET 请求 |
| `post<T>(path, {...})` | 发起 POST 请求 |
| `put<T>(path, {...})` | 发起 PUT 请求 |
| `delete<T>(path, {...})` | 发起 DELETE 请求 |
| `upload<T>(path, {files, ...})` | 文件上传（multipart/form-data） |
| `download(urlPath, savePath, {...})` | 文件下载，返回本地保存路径 |
| `addInterceptor(interceptor)` | 动态添加 Dio 拦截器 |
| `removeInterceptor(interceptor)` | 动态移除 Dio 拦截器 |
| `configure(config)` | 运行时更新全局配置 |

---

### `QcHttpConfig` — 全局配置

```dart
QcHttpConfig({
  String baseUrl = '',                                    // 服务器根地址
  Duration connectTimeout = const Duration(seconds: 10), // 连接超时
  Duration receiveTimeout = const Duration(seconds: 10), // 接收超时
  Duration sendTimeout = const Duration(seconds: 10),    // 发送超时
  Map<String, dynamic> headers = const {},               // 全局请求头
  String contentType = Headers.jsonContentType,          // Content-Type
  bool enableLog = true,                                 // 是否开启日志
});
```

支持 `copyWith()` 方法按需覆盖特定字段：

```dart
final newConfig = config.copyWith(baseUrl: 'https://new-api.example.com');
http.configure(newConfig);
```

---

### `QcResponse<T>` — 统一响应体

```dart
class QcResponse<T> {
  T? data;              // 响应数据
  int statusCode;       // HTTP 状态码
  String? statusMessage; // HTTP 状态信息
  Headers? headers;     // 响应头
  bool isSuccess;       // 是否 2xx 成功
}
```

常用属性：

```dart
res.isOk                     // 同 isSuccess
res.getHeader('Content-Type') // 获取响应头
res.getDataOrDefault({})      // 数据为空时返回默认值
```

---

### `QcHttpException` — 统一异常

```dart
class QcHttpException implements Exception {
  final String message;      // 错误描述
  final int code;            // 业务/HTTP 错误码
  final QcResponse? response; // 原始响应（如有）
  final QcExceptionType type; // 精细分类
}
```

**快捷判断属性：**

```dart
e.isUnauthorized   // 是否 Token 失效（401 / 业务码 10001）
e.isBusinessError  // 是否业务逻辑错误
e.isTimeoutError   // 是否超时（连接/发送/接收）
e.isConnectionError // 是否网络连接错误或证书错误
e.isCanceled       // 是否用户主动取消
```

**异常类型枚举 `QcExceptionType`：**

| 枚举值 | 触发场景 |
|--------|---------|
| `businessError` | 服务器返回业务错误（code ≠ 200） |
| `unauthorized` | HTTP 401 或业务 code 10001 |
| `cancel` | 请求被 `QcCancelToken.cancel()` 取消 |
| `connectionTimeout` | 建立连接超时 |
| `sendTimeout` | 请求体发送超时 |
| `receiveTimeout` | 等待响应超时 |
| `badResponse` | HTTP 4xx / 5xx 错误 |
| `badCertificate` | SSL 证书验证失败 |
| `connectionError` | 网络不通或 DNS 解析失败 |
| `unknown` | 其他未知错误 |

---

### `QcRequestOptions` — 单次请求配置

对某个请求单独定制配置，不影响全局：

```dart
await http.get(
  '/special/api',
  options: QcRequestOptions(
    receiveTimeout: const Duration(seconds: 30), // 此请求单独延长超时
    headers: {'X-Extra-Key': 'value'},           // 附加请求头
    responseType: ResponseType.bytes,            // 返回二进制流
  ),
);
```

---

### `QcCancelToken` — 请求取消

```dart
final token = QcCancelToken();

// 发起请求时传入
http.get('/long/task', cancelToken: token);

// 在需要时取消（例如页面销毁）
token.cancel('用户离开页面');

// 检查是否已取消
if (token.isCancelled) { ... }

// 取消回调
token.whenCancelled(() => print('已取消'));
```

---

### `QcConverter<T>` — 数据转换器

将响应 `data` 转换为目标类型：

```dart
// 使用内置转换器
final res = await http.get<Map<String, dynamic>>(
  '/user/info',
  converter: QcJsonToMapConverter(),
);

// 自定义转换器（常用于 Model 映射）
class UserConverter extends QcConverter<UserModel> {
  @override
  UserModel convert(dynamic data) => UserModel.fromJson(data);
}

final res = await http.get<UserModel>(
  '/user/info',
  converter: UserConverter(),
);
final user = res.data; // UserModel 类型
```

**内置转换器：**

| 类名 | 用途 |
|------|------|
| `QcJsonToMapConverter` | 响应转 `Map<String, dynamic>` |
| `QcJsonToListConverter<T>` | 响应转 `List<T>`，需传入 item 转换器 |

---

## 🔌 拦截器使用指南

### `QcLogInterceptor` — 日志拦截器（已内置，无需手动添加）

当 `QcHttpConfig.enableLog = true` 时自动启用。控制台输出效果：

```
╔═══════════════════ QC 网络日志 (QC-NETWORK) ═══════════════════
║ 🚀 [接口]: POST https://api.example.com/order/create
║ ⏱️ [耗时]: 342ms
║ 📦 [Body]: {"productId":"p001","qty":2}
║ ✅ [状态]: 200
║ 📥 [数据]: {"code":200,"msg":"ok","data":{"orderId":"ORD123"}}
╚═══════════════════════════════════════════════════════════════
```

- 请求与响应**合并输出**，并发请求日志不交叉
- 自动统计**请求耗时**（ms）
- 超长响应自动**截断**（默认 4KB），可通过 `maxLogLength` 自定义
- 使用 `dart:developer` 的 `log` 方法，过滤 tag：`QC-NETWORK`

```dart
// 自定义最大日志长度
http.addInterceptor(QcLogInterceptor(maxLogLength: 1024 * 8));
```

---

### `QcAuthInterceptor` — 认证拦截器

继承此抽象类并实现三个方法即可：

```dart
class AppAuthInterceptor extends QcAuthInterceptor {
  AppAuthInterceptor(super.dio);

  @override
  Future<String?> getToken() async {
    // 从本地存储获取 Token
    return StorageService.instance.getToken();
  }

  @override
  Future<Map<String, dynamic>> getExtraHeaders() async {
    // 注入公共请求头（如设备号、语言等）
    return {
      'X-Client-Version': '1.0.0',
      'X-Language': 'zh-TW',
    };
  }

  @override
  Future<bool> refreshToken() async {
    // 刷新 Token 逻辑
    try {
      final newToken = await AuthRepository.refreshToken();
      await StorageService.instance.saveToken(newToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isTokenInvalid(Response response) {
    // 根据业务自定义 Token 失效判断（如使用特殊业务码）
    if (response.data is Map) {
      final code = response.data['code'];
      return code == 10001 || code == 401;
    }
    return response.statusCode == 401;
  }
}

// 注册到 QcHttp
http.addInterceptor(AppAuthInterceptor(http.dio));
```

**工作流程：**

```
请求发出
  └─ onRequest: 自动注入 Token 和公共 Header
       └─ 响应返回
            ├─ isTokenInvalid == false → 正常透传
            └─ isTokenInvalid == true
                 ├─ refreshToken() 成功 → 重发原请求（自动透明重试）
                 └─ refreshToken() 失败 → 透传原始响应
```

> 使用 `QueuedInterceptor` 保证多请求并发时 Token 刷新只执行一次，避免竞态。

---

### `QcSignInterceptor` — 签名拦截器

继承此抽象类，实现签名算法即可：

```dart
class AppSignInterceptor extends QcSignInterceptor {
  @override
  String generateSign(Map<String, dynamic> params) {
    // 示例：参数键名排序后拼接，再 MD5 哈希
    final sortedKeys = params.keys.toList()..sort();
    final signStr = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    return md5Hash('$signStr&secret=YOUR_SECRET_KEY');
  }

  @override
  bool get injectToQuery => false; // 签名注入到 Header 而非 Query

  @override
  String get signKey => 'X-Signature'; // 自定义 Header 键名
}
```

**签名收集规则：**

- 自动合并 `queryParameters` + `body`（仅 Map 类型）参数
- 调用 `generateSign()` 生成签名字符串
- 根据 `injectToQuery` 决定注入位置（`Query` 或 `Header`）

---

## 🔁 文件上传与下载

### 文件上传

```dart
import 'package:dio/dio.dart';

final file = await MultipartFile.fromFile(
  '/local/path/image.jpg',
  filename: 'image.jpg',
);

final res = await http.upload<Map<String, dynamic>>(
  '/file/upload',
  files: [file],
  fileKey: 'file',          // 服务端接收字段名，默认 'files'
  data: {'bizType': 'avatar'}, // 附加表单参数
  onSendProgress: (sent, total) {
    final progress = (sent / total * 100).toStringAsFixed(1);
    print('上传进度: $progress%');
  },
);
```

### 文件下载

```dart
final res = await http.download(
  '/file/report.pdf',        // 服务端路径
  '/local/save/report.pdf',  // 本地保存路径
  onReceiveProgress: (received, total) {
    final progress = (received / total * 100).toStringAsFixed(1);
    print('下载进度: $progress%');
  },
);

print('文件已保存至: ${res.data}'); // 返回本地路径字符串
```

---

## 🧩 业务响应解析规则

`QcHttp` 内置业务层判断，会在 HTTP 200 的情况下**进一步检查业务码**：

| 检查字段 | 成功条件 |
|---------|---------|
| `code` 或 `Code` | 值为 `200` |
| `success` 或 `Success` | 值为 `true` |
| 无以上字段 | 直接视为成功 |

错误信息提取优先级：`Msg` > `msg` > `Message` > `message` > `'业务处理失败'`

> ⚠️ 如果业务约定不同，可通过继承 `QcHttp` 并重写 `_isBusinessSuccess` / `_getBusinessErrorMessage` 来自定义。

---

## 📐 在 QcAppFlow 框架中的推荐用法

在 `QcAppFlow` 框架中，请通过上层封装的 `QcNetwork` 发起请求，而非直接使用 `QcHttp`。

```dart
// ✅ 推荐：使用框架封装的 QcNetwork
final res = await QcNetwork.get('/api/user/profile');
final res = await QcNetwork.post('/api/order/create', data: {...});

// ❌ 禁止：直接 new QcHttp() 或 raw Dio
```

如需在 `Repository` 层使用：

```dart
class UserRepository {
  Future<dynamic> getUserProfile() async {
    return await QcNetwork.get('/user/profile');
  }
}
```

---

## 📁 文件结构

```
lib/
├── qc_app_flow_network.dart    # 统一导出入口
├── qc_http.dart                # 核心 HTTP 客户端
├── qc_http_config.dart         # 全局配置类
├── qc_response.dart            # 统一响应体
├── qc_request_options.dart     # 单次请求配置
├── qc_converter.dart           # 数据转换器接口与内置实现
├── qc_cancel_token.dart        # 请求取消工具
├── qc_exception.dart           # 统一异常类与类型枚举
├── qc_auth_interceptor.dart    # 抽象认证拦截器
├── qc_sign_interceptor.dart    # 抽象签名拦截器
├── qc_log_interceptor.dart     # 日志拦截器
└── meta/
    └── qc_meta.dart            # 元注解定义（QcMethod/QcWidget 等）
```

---

## 📋 依赖关系

```yaml
dependencies:
  dio: ^5.9.2   # 底层 HTTP 客户端
  flutter:
    sdk: flutter
```

---

## 📝 更新日志

### v0.0.1
- 🎉 初始版本发布
- 实现 `QcHttp` 核心请求类（GET/POST/PUT/DELETE/上传/下载）
- 实现 `QcAuthInterceptor`：Token 自动注入 + 刷新重试（QueuedInterceptor 防竞态）
- 实现 `QcSignInterceptor`：可扩展参数签名框架
- 实现 `QcLogInterceptor`：请求响应合并日志 + 耗时统计 + 智能截断
- 实现 `QcHttpException` + `QcExceptionType`：10 种精细异常分类
- 实现 `QcConverter<T>`：通用响应数据转换器接口
- 实现 `QcCancelToken`：安全的请求取消封装
- 实现 `QcResponse<T>`：统一泛型响应体

---

> 📮 **维护者**: QcAppFlow Team  
> 🔗 **所属框架**: [tjy_multi_getx_pro](../../README.md)
