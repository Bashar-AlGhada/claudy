import 'package:flutter_test/flutter_test.dart';
import 'package:claudy/core/diagnostics/diagnostics_service.dart';

void main() {
  test('collects diagnostics with architecture detection', () async {
    final svc = DiagnosticsService();
    final bundle = await svc.collect();
    expect(bundle['platform'], isNotNull);
    final platform = bundle['platform'] as Map<String, Object?>;
    expect(platform['architecture'], isNotNull);
    expect(platform['os'], isNotEmpty);
  });
}
