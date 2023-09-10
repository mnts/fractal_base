import 'package:fractal/fractal.dart';
import 'package:fractal_base/extensions/stored.dart';
import 'package:signed_fractal/controllers/events.dart';
import 'package:signed_fractal/models/event.dart';
import 'package:sqlite3/common.dart';

import '../models/table.dart';

extension SqlFractalExt on FractalCtrl {
  TableF initSql() => dbf.tables.firstWhere(
        (t) => t.name == name,
        orElse: () => _initTable(),
      );
  //_columns();

  static init() {}

  List listValues(MP map) => attributes
      .map(
        (attr) => map[attr.name],
      )
      .toList();

  List<FractalCtrl> get controllers {
    final ctrls = <FractalCtrl>[this];

    while (ctrls.last.extend is FractalCtrl) {
      ctrls.add(ctrls.last.extend as FractalCtrl);
    }
    return ctrls.sublist(1, ctrls.length - 1);
  }

  static int fid = 0;
  int store(MP map) {
    // upsert

    db.execute("BEGIN;");
    _insertion(
      Fractal.controller,
      Fractal.controller.listValues(map),
    );
    map['id'] = fid = db.lastInsertRowId;

    //query(INSERT OR REPLACE INTO variables VALUES ('fid', last_insert_rowid()););
    final ctrls = controllers;
    for (final ctrl in ctrls.reversed) {
      _insertion(
        ctrl,
        ctrl.listValues(map),
      );
    }

    _insertion(this, listValues(map));

    db.execute("COMMIT;");
    //'INSERT INTO $name (${map.keys.join(',')}) VALUES (${map.keys.map((e) => '?').join(',')}) ON CONFLICT(id) DO UPDATE SET ${map.keys.map((e) => '$e=?').join(',')}',
    print(
      '$name#$fid stored ${ctrls.map((c) => c.attributes.map((a) => a.name).join(',')).join(';')}',
    );
    print(map);

    return fid;
  }

  bool get _isMain => runtimeType == FractalCtrl;

  _insertion(FractalCtrl c, List<Object?> list) => query(
      """
INSERT INTO ${c.name} (
  ${c.attributes.map((attr) => "'${attr.name}'").join(',')}${!c._isMain ? ',id_fractal' : ''}
) 
VALUES (
  ${c.attributes.map((e) => '?').join(',')}${!c._isMain ? ',$fid' : ''}
);
  """,
      list);

  TableF _initTable() {
    //_columns();

    //final ctrl = controllers.firstOrNull;
    query(
        """
CREATE TABLE IF NOT EXISTS $name (
  id INTEGER PRIMARY KEY,
  ${attributes.map((attr) => attr.sqlDefinition).join(',\n')}
  ${runtimeType != FractalCtrl ? """,
    'id_fractal' INTEGER NOT NULL,
    FOREIGN KEY(id_fractal) REFERENCES fractal(id)
  """ : ""}
)
    """);
    return TableF(
      name: name,
      attributes: attributes,
    );
    //${ctrl != null ? ",'id_${ctrl.name}' INTEGER NOT NULL" : ''}
  }

  _columns() {
    final pragma = db.select('''
      PRAGMA table_info($name)
    ''');
    print(pragma);
  }

  _removeTable() {
    dbf.db.execute('''
      DROP TABLE IF EXISTS $name
    ''');
  }

  ResultSet select() {
    //parents;
    final name = this.name;
    final query = <String>["SELECT *, fractal.id as id FROM $name"];

    for (final ctrl in controllers) {
      final cname = ctrl.name;
      query.add(
          '''
        INNER JOIN $cname ON 
        $cname.id_fractal = $name.id_fractal
        ''');
    }

    query.add(
        '''
      INNER JOIN fractal ON 
      $name.id_fractal = fractal.id AND fractal.type = '$name'
    ''');

    final rows = db.select(
      query.join('\n'),
    );

    return rows;
  }
}
