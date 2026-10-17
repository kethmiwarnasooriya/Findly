import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Applies to every test: a tap that would not reach its target fails the
/// test instead of printing a warning.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
