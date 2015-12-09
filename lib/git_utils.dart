library tekartik_io_tools.git_utils;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:process_run/cmd_run.dart';
import 'src/scpath.dart';
import 'package:path/path.dart';

bool _DEBUG = false;

class GitStatusResult {
  final ProcessResult runResult;

  GitStatusResult(this.runResult);

  bool nothingToCommit = false;
  bool branchIsAhead = false;
}

class GitPath {
  String _path;

  String get path => _path;

  GitPath(this._path);

  GitPath._();

  ProcessCmd _gitCmd(List<String> args) {
    ProcessCmd cmd = gitCmd(args)..workingDirectory = path;
    return cmd;
  }

  ProcessCmd pullCmd() {
    return _gitCmd(['pull']);
  }

  /*
  Future<ProcessResult> _run(List<String> args, {bool dryRun}) async {
    if (dryRun == true) {
      stdout.writeln("git ${args.join(' ')} [$path]");
      return null;
    } else {
      return gitRun(args, workingDirectory: path);
    }
  }
  */

  /// printResultIfChanges: show result if different than 'nothing to commit'
  Future<GitStatusResult> status({bool printResultIfChanges}) async {
    ProcessResult result = await runCmd(_gitCmd(['status']));
    GitStatusResult statusResult = new GitStatusResult(result);

    if (result.exitCode == 0) {
      Iterable<String> lines = LineSplitter.split(result.stdout);

      lines.forEach((String line) {
        // Linux /Win?/Mac?
        if (line.startsWith('nothing to commit')) {
          statusResult.nothingToCommit = true;
        }
        if (line.startsWith('Your branch is ahead of') ||
                line.startsWith(
                    '# Your branch is ahead of') // output of drone io
            ) {
          statusResult.branchIsAhead = true;
        }
      });
    }

    return statusResult;
  }

  ProcessCmd addCmd({String pathspec}) {
    List<String> args = ['add', pathspec];
    return _gitCmd(args);
  }

  ProcessCmd commitCmd(String message, {bool all}) {
    List<String> args = ['commit'];
    if (all == true) {
      args.add("--all");
    }
    args.addAll(['-m', message]);
    return _gitCmd(args);
  }

  ///
  /// branch can be a commit/revision number
  ProcessCmd checkoutCmd({String commit}) {
    return _gitCmd(['checkout', commit]);
  }
}

class GitProject extends GitPath {
  String src;

  GitProject(this.src, {String path, String rootFolder}) : super._() {
    // Handle null
    if (path == null) {
      var parts = scUriToPathParts(src);

      _path = joinAll(parts);

      if (_path == null) {
        throw new Exception(
            'null path only allowed for https://github.com/xxxuser/xxxproject src');
      }
      if (rootFolder != null) {
        _path = absolute(join(rootFolder, path));
      } else {
        _path = absolute(_path);
      }
    } else {
      this._path = path;
    }
  }

  // no using _gitCmd as not using workingDirectory
  ProcessCmd cloneCmd({bool progress}) {
    List<String> args = ['clone'];
    if (progress == true) {
      args.add('--progress');
    }
    args.addAll([src, path]);
    return gitCmd(args);
  }

  Future pullOrClone() {
    // TODO: check the origin branch
    if (new File(join(path, '.git', 'config')).existsSync()) {
      return runCmd(pullCmd());
    } else {
      return runCmd(cloneCmd());
    }
  }
}

/// Version command
ProcessCmd gitVersionCmd() => gitCmd(['--version']);

/// check if git is supported
Future<bool> get isGitSupported async {
  try {
    await runCmd(gitVersionCmd());
    return true;
  } catch (e) {
    return false;
  }
}

ProcessCmd gitCmd(List<String> args) => processCmd('git', args);

/*
Future<ProcessResult> gitRun(List<String> args,
    {String workingDirectory, bool connectIo: false}) {
  if (_DEBUG) {
    print('running git ${args}');
  }
  return run('git', args,
      workingDirectory: workingDirectory, connectStderr: connectIo, connectStdout: connectIo).catchError((e) {
    // Caught ProcessException: No such file or directory

    if (e is ProcessException) {
      print("${e.executable} ${e.arguments}");
      print(e.message);
      print(e.errorCode);

      if (e.message.contains("No such file or directory") &&
          (e.errorCode == 2)) {
        print('GIT ERROR: make sure you have git installed in your path');
      }
    }
    throw e;
  }).then((ProcessResult result) {
    if (_DEBUG) {
      print('result: ${result}');
    }
    return result;
  });
}


@deprecated
Future gitPull(String path) {
  return gitRun(['pull'], workingDirectory: path);
}

@deprecated
Future gitStatus(String path) {
  return gitRun(['status'], workingDirectory: path);
}
*/
/// Check if an url is a git repository
Future<bool> isGitRepository(String uri) async {
  ProcessResult runResult =
      await runCmd(gitCmd(['ls-remote', '--exit-code', '-h', uri]));
  // 2 is returned if not found
  // 128 if an error occured
  return (runResult.exitCode == 0) || (runResult.exitCode == 2);
}

Future<bool> isGitTopLevelPath(String path) async {
  String dotGit = ".git";
  String gitFile = join(path, dotGit);
  return await FileSystemEntity.isDirectory(gitFile);
}
