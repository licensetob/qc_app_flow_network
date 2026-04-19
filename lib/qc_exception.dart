import 'qc_response.dart';

/// 异常类型枚举
enum QcExceptionType {
  businessError, // 业务逻辑错误
  unauthorized, // 认证失败或 Token 无效
  cancel, // 请求取消
  connectionTimeout, // 连接超时
  sendTimeout, // 发送超时
  receiveTimeout, // 接收超时
  badResponse, // 响应错误
  badCertificate, // 证书错误
  connectionError, // 连接错误
  unknown, // 未知错误
}

/// 网络请求异常类
class QcHttpException implements Exception {
  final String message;
  final int code;
  final QcResponse? response;
  final QcExceptionType type;
  
  QcHttpException({
    required this.message,
    required this.code,
    this.response,
    required this.type,
  });
  
  /// 判断是否是认证失败
  bool get isUnauthorized => type == QcExceptionType.unauthorized;
  
  /// 判断是否是业务错误
  bool get isBusinessError => type == QcExceptionType.businessError;
  
  /// 判断是否是超时错误
  bool get isTimeoutError => 
      type == QcExceptionType.connectionTimeout || 
      type == QcExceptionType.sendTimeout || 
      type == QcExceptionType.receiveTimeout;
  
  /// 判断是否是网络连接错误
  bool get isConnectionError => 
      type == QcExceptionType.connectionError ||
      type == QcExceptionType.badCertificate;
  
  /// 判断是否是用户取消
  bool get isCanceled => type == QcExceptionType.cancel;
  
  @override
  String toString() {
    return 'QcHttpException{message: $message, code: $code, type: $type}';
  }
}
    