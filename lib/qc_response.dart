import 'package:dio/dio.dart';

/// 统一响应格式
class QcResponse<T> {
  T? data;
  int statusCode;
  String? statusMessage;
  Headers? headers;
  RequestOptions? requestOptions;
  bool isSuccess;

  QcResponse({
    this.data,
    required this.statusCode,
    this.statusMessage,
    this.headers,
    this.requestOptions,
    this.isSuccess = false,
  });

  factory QcResponse.fromDioResponse(Response response) {
    return QcResponse(
      data: response.data,
      statusCode: response.statusCode ?? -1,
      statusMessage: response.statusMessage,
      headers: response.headers,
      requestOptions: response.requestOptions,
      isSuccess:
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300,
    );
  }

  /// 检查是否是成功的响应
  bool get isOk => isSuccess;

  /// 获取响应头信息
  String? getHeader(String name) => headers?.value(name);

  /// 获取响应数据，如果为null则返回默认值
  T? getDataOrDefault(T? defaultValue) => data ?? defaultValue;

  @override
  String toString() {
    return 'QcResponse{data: $data, statusCode: $statusCode, statusMessage: $statusMessage, isSuccess: $isSuccess}';
  }
}
