import 'dart:isolate';

import 'package:fractal/types/mp.dart';
import 'package:sqlite3/wasm.dart';
import '../async.dart';
import '../db.dart';
import 'abstract.dart';

Future<CommonDatabase> openDBSync(
    AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) async {
  OpenDatabaseParams params = cmd.body;

  DBF.isWeb = true;
  final sqlite3 = await WasmSqlite3.loadFromUrl(
    Uri.parse('sqlite3.wasm'),
    //environment: SqliteEnvironment(fileSystem: fs),
  );
  final fs = await IndexedDbFileSystem.open(
    dbName: 'fractal',
  );
  sqlite3.registerVirtualFileSystem(
    fs,
    makeDefault: true,
  );

  CommonDatabase db = sqlite3.open(
    params.filename,
    vfs: params.vfs,
    mode: params.mode,
    uri: params.uri,
    mutex: params.mutex,
  );

  cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
  return db;
}
