import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxAttempts = 1,
    this.delay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxAttempts;
  final Duration delay;

  static const String _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= maxAttempts) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(delay);
    if (err.requestOptions.cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryable(DioException error) {
    if (error.requestOptions.method != 'GET') return false;
    if (error.type == DioExceptionType.cancel) return false;
    final statusCode = error.response?.statusCode ?? 0;
    if (statusCode >= 500) return true;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }
}
