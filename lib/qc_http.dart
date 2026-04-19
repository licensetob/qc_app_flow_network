import 'dart:convert';
import 'package:dio/dio.dart';
import 'qc_request_options.dart';
import 'qc_response.dart';
import 'qc_exception.dart';
import 'qc_log_interceptor.dart';
import 'qc_converter.dart';
import 'qc_cancel_token.dart';
import 'qc_http_config.dart';

class QcHttp {
  late final Dio _dio;
  late QcHttpConfig _config;

  QcHttp({QcHttpConfig? config}) {
    _config = config ?? QcHttpConfig();
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        sendTimeout: _config.sendTimeout,
        headers: _config.headers,
        contentType: _config.contentType,
      ),
    );

    // 添加默认拦截器
    if (_config.enableLog) {
      _dio.interceptors.add(QcLogInterceptor());
    }
  }

  /// 配置全局参数
  void configure(QcHttpConfig config) {
    _config = config;
    // 更新Dio的基础配置
    _dio.options.baseUrl = _config.baseUrl;
    _dio.options.connectTimeout = _config.connectTimeout;
    _dio.options.receiveTimeout = _config.receiveTimeout;
    _dio.options.sendTimeout = _config.sendTimeout;
    _dio.options.headers.addAll(_config.headers);
    _dio.options.contentType = _config.contentType;

    // 重新配置日志拦截器
    if (_config.enableLog) {
      _dio.interceptors.removeWhere(
        (interceptor) => interceptor is QcLogInterceptor,
      );
      _dio.interceptors.add(QcLogInterceptor());
    } else {
      _dio.interceptors.removeWhere(
        (interceptor) => interceptor is QcLogInterceptor,
      );
    }
  }

  /// 添加拦截器
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// 移除拦截器
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// GET请求
  Future<QcResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    QcConverter<T>? converter,
  }) async {
    return _request(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      converter: converter,
    );
  }

  /// POST请求
  Future<QcResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    QcConverter<T>? converter,
  }) async {
    return _request(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      converter: converter,
    );
  }

  /// PUT请求
  Future<QcResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    QcConverter<T>? converter,
  }) async {
    return _request(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      converter: converter,
    );
  }

  /// DELETE请求
  Future<QcResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    QcConverter<T>? converter,
  }) async {
    return _request(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      converter: converter,
    );
  }

  /// 上传文件
  Future<QcResponse<T>> upload<T>(
    String path, {
    required List<MultipartFile> files,
    String fileKey = 'files',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    QcConverter<T>? converter,
  }) async {
    final FormData formData = FormData();

    if (data != null) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    for (var file in files) {
      formData.files.add(MapEntry(fileKey, file));
    }

    return _request(
      path,
      method: 'POST',
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      converter: converter,
    );
  }

  /// 下载文件
  Future<QcResponse<String>> download(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: options?.toOptions() ?? Options(),
        cancelToken: cancelToken?.token,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
      );

      return QcResponse(
        data: savePath,
        statusCode: response.statusCode ?? -1,
        statusMessage: response.statusMessage,
        headers: response.headers,
        requestOptions: response.requestOptions,
        isSuccess: true,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 通用请求方法
  Future<QcResponse<T>> _request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    QcRequestOptions? options,
    QcCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    QcConverter<T>? converter,
  }) async {
    try {
      // 确保options中的method与参数method一致
      final requestOptions =
          options?.copyWith(method: method) ?? QcRequestOptions(method: method);

      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions.toOptions(),
        cancelToken: cancelToken?.token,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return _handleResponse(response, converter);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理响应
  QcResponse<T> _handleResponse<T>(
    Response response,
    QcConverter<T>? converter,
  ) {
    final qcResponse = QcResponse<T>.fromDioResponse(response);

    // 检查业务逻辑错误
    if (!_isBusinessSuccess(qcResponse)) {
      final code = _getBusinessErrorCode(qcResponse);
      // 根据您的具体业务自行调整哪些算是 token 过期/无效（这里暂以 401, 10001 等为示例）
      final isUnauthorized = code == 401 || code == 10001;

      throw QcHttpException(
        message: _getBusinessErrorMessage(qcResponse),
        code: code,
        response: qcResponse,
        type: isUnauthorized
            ? QcExceptionType.unauthorized
            : QcExceptionType.businessError,
      );
    }

    // 转换数据
    if (converter != null) {
      qcResponse.data = converter.convert(qcResponse.data);
    } else if (T != dynamic && qcResponse.data != null) {
      // 如果没有自定义转换器且指定了类型，尝试默认转换
      if (qcResponse.data is Map) {
        qcResponse.data = json.encode(qcResponse.data) as T;
      }
    }

    return qcResponse;
  }

  /// 处理错误
  QcHttpException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          return QcHttpException(
            message: '请求已取消',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.cancel,
          );
        case DioExceptionType.connectionTimeout:
          return QcHttpException(
            message: '连接超时',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.connectionTimeout,
          );
        case DioExceptionType.sendTimeout:
          return QcHttpException(
            message: '发送超时',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.sendTimeout,
          );
        case DioExceptionType.receiveTimeout:
          return QcHttpException(
            message: '接收超时',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.receiveTimeout,
          );
        case DioExceptionType.badResponse:
          final isUnauthorized = error.response?.statusCode == 401;
          return QcHttpException(
            message: '服务器错误: ${error.response?.statusMessage ?? "未知错误"}',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: isUnauthorized
                ? QcExceptionType.unauthorized
                : QcExceptionType.badResponse,
          );
        case DioExceptionType.badCertificate:
          return QcHttpException(
            message: '证书错误',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.badCertificate,
          );
        case DioExceptionType.connectionError:
          return QcHttpException(
            message: '连接错误',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.connectionError,
          );
        case DioExceptionType.unknown:
          return QcHttpException(
            message: '未知错误: ${error.message}',
            code: error.response?.statusCode ?? -1,
            response: error.response != null
                ? QcResponse.fromDioResponse(error.response!)
                : null,
            type: QcExceptionType.unknown,
          );
      }
    } else if (error is QcHttpException) {
      return error;
    } else {
      return QcHttpException(
        message: error.toString(),
        code: -1,
        type: QcExceptionType.unknown,
      );
    }
  }

  /// 判断业务是否成功
  bool _isBusinessSuccess(QcResponse response) {
    // 这里假设业务成功的判断标准是状态码为200且data中包含success为true
    // 实际项目中请根据后端返回格式调整
    if (response.statusCode == 200) {
      if (response.data is Map) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// 获取业务错误信息
  String _getBusinessErrorMessage(QcResponse response) {
    // 实际项目中请根据后端返回格式调整
    if (response.data is Map) {
      return response.data['message'] ?? '业务处理失败';
    }
    return '业务处理失败';
  }

  /// 获取业务错误码
  int _getBusinessErrorCode(QcResponse response) {
    // 实际项目中请根据后端返回格式调整
    if (response.data is Map) {
      return response.data['code'] ?? -1;
    }
    return -1;
  }
}
