import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';

FutureOr<Sqlite3> constructDb() {
  /*
  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      _openOnLinux,
    );
  }
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      _openOnWin,
    );
  }
  */

  return sqlite3;
}

final _scriptDir = File(Platform.script.toFilePath()).parent;

DynamicLibrary _openOnWin() {
  final libraryNextToScript = File(join(
    _scriptDir.path,
    './sqlite3.dll',
  ));
  return DynamicLibrary.open(libraryNextToScript.path);
}

DynamicLibrary _openOnLinux() {
  final libraryNextToScript = File(
    join(
      _scriptDir.path,
      'sqlite3.so',
    ),
  );
  return DynamicLibrary.open(libraryNextToScript.path);
}
