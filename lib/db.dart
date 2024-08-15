import 'dart:async';
import 'package:fractal/types/file.dart';
import 'package:path/path.dart';
import 'package:sqlite3/common.dart';
import 'access/abstract.dart';
import 'fracs/stored.dart';
import 'fractals/device.dart';
import 'models/attr.dart';
import 'models/table.dart';
import 'access/unsupported.dart'
    if (dart.library.ffi) 'access/native.dart'
    if (dart.library.html) 'access/web.dart';

class DBF {
  static final main = DBF();
  static bool isWeb = false;
  late FDBA db;
  DBF([String name = 'fractal']) {
    db = constructDb(name);

    //db.execute('END;');
  }

  Future<bool> init() async {
    await db.connect();

    //db = SqliteDatabase(path: 'test.db');

    await db.query('PRAGMA foreign_keys=OFF;');

    //clear();
    if (tables
        .where(
          (t) => t.name == 'variables',
        )
        .isEmpty) {
      await initVars();
    }

    final tbls = await db.select('''
      SELECT name FROM sqlite_schema WHERE 
      type ='table' AND 
      name NOT LIKE 'sqlite_%';
    ''');

    for (var row in tbls) {
      tables.add(
        TableF(
          name: row.values.first as String,
        ),
      );
    }
    return true;
  }

  //static late CommonSqlite3 sqlite;
  static FutureOr<bool> initiate() async {
    await main.init();
    await Attr.controller.init();
    await DeviceFractal.init();
    return true;
  }

  Future<void> setVar(String key, dynamic val) async {
    await db.query(
      "INSERT OR REPLACE INTO variables VALUES(?,?,?);",
      [
        key,
        (val is String) ? val : '',
        (val is int) ? val : 0,
      ],
    );
    final frac = StoredFrac.map[key];
    frac?.value = val;
    frac?.notifyListeners();
  }

  final tables = <TableF>[];

  Future<String?> getVar(String key) async {
    final re = await db.select(
      "SELECT value, numb FROM 'variables' WHERE name=?",
      [key],
    );
    if (re.isEmpty) return null;
    final str = re.first['value'] as String;
    return (str.isEmpty) ? '${re.first['numb']}' : re.first['value'];
  }

  clear() async {
    db.query('''
      PRAGMA writable_schema = 1;
      DELETE FROM sqlite_master;
      PRAGMA writable_schema = 0;
      VACUUM;
      PRAGMA integrity_check;
    ''');
  }

  Future<TableF> initVars() async {
    await db.query("""
      CREATE TABLE IF NOT EXISTS 'variables' 
      (name TEXT PRIMARY KEY, value TEXT, numb INTEGER);
    """);
    return TableF(name: 'vars');
  }
}
