import 'package:dio/dio.dart';
import 'dart:ui';
/// 请求取消工具类
class QcCancelToken {
  final CancelToken token;
  
  QcCancelToken() : token = CancelToken();
  
  /// 取消请求
  void cancel([dynamic reason]) {
    if (!isCancelled) {
      token.cancel(reason);
    }
  }
  
  /// 检查请求是否已取消
  bool get isCancelled => token.isCancelled;
  
  /// 当请求被取消时执行
  void whenCancelled(VoidCallback onCancel) {
    token.whenCancel.then((_) => onCancel());
  }
}
    