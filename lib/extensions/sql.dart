import 'package:fractal/fractal.dart';
import 'package:fractal_base/extensions/stored.dart';
import 'package:signed_fractal/controllers/events.dart';
import 'package:signed_fractal/models/event.dart';
import 'package:sqlite3/common.dart';

import '../models/table.dart';

extension SqlFractalExt on FractalCtrl {
  TableF initSql() => dbf.tables.firstWhere(
        (t) {
          final found = t.name == name;
          if (found) _columns();
          return found;
        },
        orElse: () => _initTable(),
      );
  //_columns();

  static init() {}

  List listValues(MP map) => attributes
      .map(
        (attr) => map[attr.name],
      )
      .toList();

  static int fid = 0;
  int store(MP map) {
    // upsert

    try {
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
    } catch (err) {
      print(err);
      db.execute("END;");
    }

    //'INSERT INTO $name (${map.keys.join(',')}) VALUES (${map.keys.map((e) => '?').join(',')}) ON CONFLICT(id) DO UPDATE SET ${map.keys.map((e) => '$e=?').join(',')}',
    /*
    print(
      '$name#$fid stored ${ctrls.map((c) => c.attributes.map((a) => a.name).join(',')).join(';')}',
    );
    print(map);
    */
    return fid;
  }

  bool get _isMain => runtimeType == FractalCtrl;

  _insertion(FractalCtrl c, List<Object?> list) {
    final l = c.attributes.isNotEmpty ? ',' : '';
    final ins = <(String, Object)>[];
    for (int i = 0; i < c.attributes.length; i++) {
      if (list[i] != null) {
        ins.add((c.attributes[i].name, list[i]!));
      }
    }

    return query("""
INSERT INTO ${c.name} (
  ${ins.map((attr) => "'${attr.$1}'").join(',')}${!c._isMain ? '${l}id_fractal' : ''}
) 
VALUES (
  ${ins.map((e) => '?').join(',')}${!c._isMain ? '$l$fid' : ''}
);
  """, ins.map((i) => i.$2).toList());
  }

  TableF _initTable() {
    final l = attributes.isNotEmpty ? ',' : '';

    //_columns();

    //final ctrl = controllers.firstOrNull;
    query("""
CREATE TABLE IF NOT EXISTS $name (
  id INTEGER PRIMARY KEY,
  ${attributes.map((attr) => attr.sqlDefinition).join(',\n')}
  ${runtimeType != FractalCtrl ? """$l
    'id_fractal' INTEGER NOT NULL,
    FOREIGN KEY(id_fractal) REFERENCES fractal(id) ON DELETE CASCADE
  """ : ""}
)
    """);
    print('Create table $name(${attributes.join(',')})');
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
    final cols = pragma.rows.map((row) => row[1]);
    for (var attr in attributes) {
      if (!cols.contains(attr.name)) {
        _addColumn(attr);
      }
    }
  }

  _addColumn(Attr attr) {
    query('ALTER TABLE $name ADD ${attr.sqlDefinition}');
  }

  _removeTable() {
    dbf.db.execute('''
      DROP TABLE IF EXISTS $name
    ''');
  }

  from() {}

  ResultSet select({Iterable<int>? only}) {
    //parents;
    final name = this.name;
    final query = <String>["SELECT *, fractal.id as id FROM $name"];

    if (only != null && only.isNotEmpty) {
      query.add('WHERE id IN(${only.join(',')})');
    }

    for (final ctrl in controllers) {
      final cname = ctrl.name;
      query.add('''
        INNER JOIN $cname ON 
        $cname.id_fractal = $name.id_fractal
      ''');
    }

    query.add('''
      INNER JOIN fractal ON 
      $name.id_fractal = fractal.id AND fractal.type = '$name'
    ''');

    final rows = db.select(
      query.join('\n'),
    );

    return rows;
  }
}
