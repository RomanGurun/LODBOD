import 'package:dio/dio.dart';

import 'package:lodbod/core/network/data_source_status.dart';

class DataSourceInterceptor extends Interceptor {
  DataSourceInterceptor(this._status);

  final DataSourceStatus _status;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _status.markLive();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isTransportFailure(err)) {
      _status.markFallback();
    }
    handler.next(err);
  }

  bool _isTransportFailure(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }
}
