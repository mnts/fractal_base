import 'dart:async';
import 'package:fractal/types/file.dart';
import 'package:path/path.dart';
import 'package:sqlite3/common.dart';
import 'fracs/stored.dart';
import 'models/table.dart';
import 'unsupported.dart'
    if (dart.library.ffi) 'native.dart'
    if (dart.library.html) 'web.dart';

class DBF {
  static final main = DBF();
  static bool isWeb = false;
  late CommonDatabase db;
  DBF([String name = 'fractal']) {
    db = sqlite.open(
      isWeb ? name : join(FileF.path, '$name.db'),
    );

    //clear();
    tables.firstWhere(
      (t) => t.name == 'variables',
      orElse: () => initVars(),
    );
  }

  static late CommonSqlite3 sqlite;
  static FutureOr<void> initiate() async {
    sqlite = await constructDb();
  }

  operator []=(String key, dynamic val) {
    db.execute(
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

  late final tables = <TableF>[
    ...db.select('''
      SELECT name FROM sqlite_schema WHERE 
      type ='table' AND 
      name NOT LIKE 'sqlite_%';
    ''').map(
      (row) => TableF(
        name: row.values.first as String,
      ),
    )
  ];

  operator [](String key) {
    final re = db.select(
      "SELECT value, numb FROM 'variables' WHERE name=?",
      [key],
    );
    if (re.isEmpty) return null;
    final str = re.first['value'] as String;
    return (str.isEmpty) ? re.first['numb'] : re.first['value'];
  }

  clear() {
    db.execute('''
      PRAGMA writable_schema = 1;
      DELETE FROM sqlite_master;
      PRAGMA writable_schema = 0;
      VACUUM;
      PRAGMA integrity_check;
    ''');
  }

  TableF initVars() {
    db.execute("""
      CREATE TABLE IF NOT EXISTS 'variables' 
      (name TEXT PRIMARY KEY, value TEXT, numb INTEGER);
    """);
    return TableF(name: 'vars');
  }
}
