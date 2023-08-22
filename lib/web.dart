import 'dart:async';

import 'package:fractal_base/index.dart';
import 'package:sqlite3/wasm.dart';

FutureOr<CommonSqlite3> constructDb() async {
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

  return sqlite3;
}
