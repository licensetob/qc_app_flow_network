import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 日志拦截器
class QcLogInterceptor extends Interceptor {
  /// 日志最大长度
  final int maxLogLength;

  QcLogInterceptor({this.maxLogLength = 1024 * 4});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('''
    ------------------- 请求开始 -------------------
    方法: ${options.method}
    URL: ${options.uri}
     headers: ${_truncateIfNeeded(options.headers.toString())}
    参数: ${_truncateIfNeeded(_getDataString(options.data))}
    查询参数: ${_truncateIfNeeded(options.queryParameters.toString())}
    ------------------- 请求结束 -------------------
    ''');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('''
    ------------------- 响应开始 -------------------
    状态码: ${response.statusCode}
    响应数据: ${_truncateIfNeeded(response.data.toString())}
    ------------------- 响应结束 -------------------
    ''');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('''
    ------------------- 错误开始 -------------------
    错误类型: ${err.type}
    状态码: ${err.response?.statusCode}
    错误信息: ${_truncateIfNeeded(err.message ?? '')}
    响应数据: ${err.response != null ? _truncateIfNeeded(err.response!.data.toString()) : '无'}
    错误堆栈: ${err.stackTrace}
    ------------------- 错误结束 -------------------
    ''');
    super.onError(err, handler);
  }

  /// 处理数据字符串
  String _getDataString(dynamic data) {
    if (data == null) return '无';
    if (data is Map || data is List) {
      try {
        return data.toString();
      } catch (e) {
        return data.toString();
      }
    } else {
      return data.toString();
    }
  }

  /// 如果字符串太长则截断
  String _truncateIfNeeded(String value) {
    if (value.length <= maxLogLength) {
      return value;
    }
    return '${value.substring(0, maxLogLength)}... [已截断，总长度: ${value.length}]';
  }
}
