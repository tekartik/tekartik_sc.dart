import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:tekartik_sc/git.dart';

Future main() async {
  print('Git supported: ${await checkGitSupported(verbose: true)}');
  print('${await runCmd(ProcessCmd('which', ['git']), verbose: true)}');
  print('${await runCmd(ProcessCmd('git', [
        '--version'
      ], runInShell: true), verbose: true)}');
}
