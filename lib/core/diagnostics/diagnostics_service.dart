import 'dart:convert';
import 'dart:io';

class DiagnosticsService {
  Future<Map<String, Object?>> collect() async {
    final env = Platform.environment;
    final arch = _detectArchitecture(env);
    final osVersion = Platform.operatingSystemVersion;
    final locale = Platform.localeName;
    final displayScale = env['GDK_SCALE'] ?? env['DISPLAY_SCALE'];

    return {
      'app': {
        'version': '1.0.0+1',
      },
      'platform': {
        'os': Platform.operatingSystem,
        'osVersion': osVersion,
        'architecture': arch,
        'locale': locale,
        'displayScale': displayScale,
        'dart': Platform.version,
      },
      'envSample': {
        'PROCESSOR_ARCHITECTURE': env['PROCESSOR_ARCHITECTURE'],
        'PROCESSOR_ARCHITEW6432': env['PROCESSOR_ARCHITEW6432'],
        'NUMBER_OF_PROCESSORS': env['NUMBER_OF_PROCESSORS'],
      },
      'notes': 'No secrets or precise location are included.',
    };
  }

  String _detectArchitecture(Map<String, String> env) {
    final primary = (env['PROCESSOR_ARCHITECTURE'] ?? '').toLowerCase();
    final wow64 = (env['PROCESSOR_ARCHITEW6432'] ?? '').toLowerCase();
    final candidate = [primary, wow64].firstWhere(
      (e) => e.isNotEmpty,
      orElse: () => '',
    );
    if (candidate.contains('arm64')) return 'arm64';
    if (candidate.contains('amd64') || candidate.contains('x86_64')) return 'x64';
    if (candidate.contains('x86')) return 'x86';
    return 'unknown';
  }

  Future<File> exportToTemp(Map<String, Object?> bundle) async {
    final dir = Directory.systemTemp.createTempSync('claudy_diag_');
    final file = File('${dir.path}${Platform.pathSeparator}diagnostics.json');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(bundle);
    await file.writeAsString(jsonStr, flush: true);
    return file;
  }
}
