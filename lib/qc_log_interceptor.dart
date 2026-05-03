import 'dart:developer' as dev;
import 'package:dio/dio.dart';

/// 统一网络日志拦截器
/// 功能：
/// 1. 请求与响应合并输出，避免并发请求时日志交叉。
/// 2. 自动统计请求耗时。
/// 3. 支持超长日志截断保护。
class QcLogInterceptor extends Interceptor {
  /// 日志最大长度
  final int maxLogLength;

  QcLogInterceptor({this.maxLogLength = 1024 * 4});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 记录开始时间，用于耗时统计
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    // 请求开始阶段不再打印，等待响应后合并输出
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _printCombinedLog(response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _printCombinedLog(err.requestOptions, error: err);
    handler.next(err);
  }

  /// 合并打印请求详情与响应内容
  void _printCombinedLog(RequestOptions options, {Response? response, DioException? error}) {
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final startTime = options.extra['startTime'] ?? endTime;
    final duration = endTime - startTime;

    final isError = error != null || (response != null && response.statusCode != 200);
    final statusIcon = isError ? '❌' : '✅';
    
    final buffer = StringBuffer();
    buffer.writeln('\n╔═══════════════════ QC 网络日志 (QC-NETWORK) ═══════════════════');
    
    // 1. 请求行
    buffer.writeln('║ 🚀 [接口]: ${options.method} ${options.uri}');
    buffer.writeln('║ ⏱️ [耗时]: ${duration}ms');
    
    // 2. 请求参数
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('║ ❓ [Query]: ${options.queryParameters}');
    }
    if (options.data != null) {
      buffer.writeln('║ 📦 [Body]: ${_truncateIfNeeded(options.data.toString())}');
    }

    // 3. 响应/错误详情
    if (response != null) {
      buffer.writeln('║ $statusIcon [状态]: ${response.statusCode}');
      buffer.writeln('║ 📥 [数据]: ${_truncateIfNeeded(response.data.toString())}');
    } else if (error != null) {
      buffer.writeln('║ $statusIcon [错误]: ${error.type}');
      buffer.writeln('║ 💬 [消息]: ${error.message}');
      if (error.response != null) {
        buffer.writeln('║ 📥 [错误数据]: ${_truncateIfNeeded(error.response!.data.toString())}');
      }
    }
    
    buffer.writeln('╚═══════════════════════════════════════════════════════════════');
    
    // 使用 dart:developer 的 log 方法，name 设置为 QC-NETWORK 方便在日志过滤器中筛选
    dev.log(buffer.toString(), name: 'QC-NETWORK');
  }

  /// 数据处理与截断
  String _truncateIfNeeded(String value) {
    if (value.length <= maxLogLength) {
      return value;
    }
    return '${value.substring(0, maxLogLength)}... [已截断，总长度: ${value.length}]';
  }
}
