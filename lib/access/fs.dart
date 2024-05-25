import 'dart:isolate';

import 'package:fractal_base/async.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

Future<CommonDatabase> openDBSync(
    AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) async {
  OpenDatabaseParams params = cmd.body;
  Database db = sqlite3.open(params.filename,
      vfs: params.vfs, mode: params.mode, uri: params.uri, mutex: params.mutex);
  cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
  return db;
}
