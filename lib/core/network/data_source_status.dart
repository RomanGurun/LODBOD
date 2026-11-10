import 'package:flutter/foundation.dart';

class DataSourceStatus {
  final ValueNotifier<bool> usingFallback = ValueNotifier<bool>(false);

  void markFallback() => usingFallback.value = true;

  void markLive() => usingFallback.value = false;

  void dispose() => usingFallback.dispose();
}
