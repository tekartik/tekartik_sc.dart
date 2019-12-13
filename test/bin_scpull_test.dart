@TestOn('vm')
library tekartik_sc.test.bin_scpull_test;

import 'dart:convert';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_pub/io.dart';
import 'package:tekartik_sc/src/bin_version.dart';

import 'io_test_common.dart';

String get _pubPackageRoot => '.';

String get scpullDartScript {
  final pkg = PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'scpull.dart');
}

void main() {
  //useVMConfiguration();
  group('scpull', () {
    test('version', () async {
      final result = await runCmd(DartCmd([scpullDartScript, '--version']));
      final parts =
          LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'scpull');
      expect(Version.parse(parts.last), version);
    });
  });
}
