library tekartik_sc.sc_utils;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'hg_utils.dart';
import 'git_utils.dart';

String git = "git";
String hg = "hg";

///
/// Check whether the path is a mercurial or git path
///
Future<bool> isScTopLevelPath(String path) async {
  return ((await getScName(path)) != null);
}

///
/// Only valid at the current path
///
Future<String> getScName(String path) async {
  if (await isGitTopLevelPath(path)) {
    return git;
  }
  if (await isHgTopLevelPath(path)) {
    return hg;
  }
  return null;
}

///
/// checking recursively the parent for any hg or git directory
///
Future<String> findScTopLevelPath(String path) async {
  String parent;
  while (true) {
    if (await FileSystemEntity.isDirectory(path)) {
      if (await isScTopLevelPath(path)) {
        return path;
      }
    }
    parent = dirname(path);
    if (parent == path) {
      break;
    }
    path = parent;
  }
  return null;
}
