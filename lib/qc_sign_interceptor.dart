import 'package:dio/dio.dart';

/// 抽象的签名拦截器基类
/// 提供针对业务请求参数进行哈希、排序及签名的基础骨架
abstract class QcSignInterceptor extends Interceptor {
  /// 供子类实现：签名生成算法（例如基于参数的键自然排序后拼接 MD5）
  String generateSign(Map<String, dynamic> params);

  /// 供子类决定：签名结果放入请求头还是查询参数
  /// 默认放入 query 参数中
  bool get injectToQuery => true;

  /// 供子类决定：签名结果放入请求头或查询参数使用的键名
  String get signKey => 'sign';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Map<String, dynamic> allParams = {};

    // 收集查询参数
    if (options.queryParameters.isNotEmpty) {
      allParams.addAll(options.queryParameters);
    }

    // 收集表单/JSON等请求体参数
    if (options.data != null && options.data is Map<String, dynamic>) {
      allParams.addAll(options.data as Map<String, dynamic>);
    }

    // 生成签名
    if (allParams.isNotEmpty) {
      final String sign = generateSign(allParams);

      if (injectToQuery) {
        // 保证 QueryParameters 可修改
        options.queryParameters = Map<String, dynamic>.from(options.queryParameters);
        options.queryParameters[signKey] = sign;
      } else {
        options.headers[signKey] = sign;
      }
    }

    super.onRequest(options, handler);
  }
}
