import 'package:dio/dio.dart';

/// 请求配置选项
class QcRequestOptions {
  final String? method;
  final Duration? sendTimeout;
  final Duration? receiveTimeout;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? extra;
  final String? contentType;
  final ResponseType? responseType;
  final bool? persistentConnection;
  final bool? followRedirects;
  final int? maxRedirects;
  final RequestEncoder? requestEncoder;
  final ResponseDecoder? responseDecoder;
  final ValidateStatus? validateStatus;
  final bool? receiveDataWhenStatusError;
  final String? path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  
  QcRequestOptions({
    this.method,
    this.sendTimeout,
    this.receiveTimeout,
    this.headers,
    this.extra,
    this.contentType,
    this.responseType,
    this.persistentConnection,
    this.followRedirects,
    this.maxRedirects,
    this.requestEncoder,
    this.responseDecoder,
    this.validateStatus,
    this.receiveDataWhenStatusError,
    this.path,
    this.data,
    this.queryParameters,
  });
  
  /// 转换为Dio的Options
  Options toOptions() {
    return Options(
      method: method,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
      extra: extra,
      contentType: contentType,
      responseType: responseType,
      persistentConnection: persistentConnection,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
    );
  }
  
  /// 创建一个新的QcRequestOptions，复制当前配置并替换指定参数
  QcRequestOptions copyWith({
    String? method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    String? contentType,
    ResponseType? responseType,
    bool? persistentConnection,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    String? path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return QcRequestOptions(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      headers: headers ?? this.headers,
      extra: extra ?? this.extra,
      contentType: contentType ?? this.contentType,
      responseType: responseType ?? this.responseType,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      path: path ?? this.path,
      data: data ?? this.data,
      queryParameters: queryParameters ?? this.queryParameters,
    );
  }
}
    