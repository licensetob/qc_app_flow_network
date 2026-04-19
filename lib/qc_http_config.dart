import 'package:dio/dio.dart';

/// 全局配置类
class QcHttpConfig {
  String baseUrl;
  Duration connectTimeout;
  Duration receiveTimeout;
  Duration sendTimeout;
  Map<String, dynamic> headers;
  String contentType;
  bool enableLog;
  
  QcHttpConfig({
    this.baseUrl = '',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 10),
    this.headers = const {},
    this.contentType = Headers.jsonContentType,
    this.enableLog = true,
  });
  
  /// 创建一个新的QcHttpConfig，复制当前配置并替换指定参数
  QcHttpConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    String? contentType,
    bool? enableLog,
  }) {
    return QcHttpConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      headers: headers ?? this.headers,
      contentType: contentType ?? this.contentType,
      enableLog: enableLog ?? this.enableLog,
    );
  }
}
    