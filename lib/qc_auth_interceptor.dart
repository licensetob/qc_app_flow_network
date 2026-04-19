import 'package:dio/dio.dart';

/// 抽象的认证拦截器基类
/// 支持从业务层动态注入认证 Token、设备头等信息
/// 支持 Token 过期时的刷新重试逻辑 (无 UI 依赖)
abstract class QcAuthInterceptor extends QueuedInterceptor {
  final Dio dio;

  QcAuthInterceptor(this.dio);

  /// 供子类实现：获取当前认证 Token
  Future<String?> getToken();

  /// 供子类实现：获取额外的公共请求头（例如 clientNo, language 等）
  Future<Map<String, dynamic>> getExtraHeaders() async => {};

  /// 供子类实现：刷新 Token 逻辑
  /// 如果刷新成功返回 true，失败返回 false
  Future<bool> refreshToken();

  /// 供子类重写：判断引发 Token 无效的具体响应特征
  /// 默认判断 401 状态码，如果业务上使用特定的错误码也可在此覆盖判断
  bool isTokenInvalid(Response response) {
    return response.statusCode == 401;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 注入 Token
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 注入其他公共 Header
    final extraHeaders = await getExtraHeaders();
    if (extraHeaders.isNotEmpty) {
      options.headers.addAll(extraHeaders);
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 尝试在响应层面拦截 Token 过期（如果业务返回 200 HTTP状态码但包含错误业务码）
    if (isTokenInvalid(response)) {
      final success = await _handleTokenRefresh(response.requestOptions);
      if (success) {
        try {
          // 重发请求
          final retryResponse = await dio.request(
            response.requestOptions.path,
            data: response.requestOptions.data,
            queryParameters: response.requestOptions.queryParameters,
            options: Options(
              method: response.requestOptions.method,
              headers: response.requestOptions.headers,
            ),
          );
          return handler.next(retryResponse);
        } catch (e) {
          // 重发失败
          return handler.next(response);
        }
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 拦截 401 等 HTTP 标准错误
    if (err.response != null && isTokenInvalid(err.response!)) {
      final success = await _handleTokenRefresh(err.requestOptions);
      if (success) {
        try {
          // 重发请求
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    super.onError(err, handler);
  }

  Future<bool> _handleTokenRefresh(RequestOptions requestOptions) async {
    final bool isSuccess = await refreshToken();
    if (isSuccess) {
      final newToken = await getToken();
      if (newToken != null && newToken.isNotEmpty) {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        return true;
      }
    }
    return false;
  }
}
