import 'package:fractal/fractal.dart';
import 'package:sqlite3/common.dart';

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
    //print(map);
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

  static String _str(Object o) => switch (o) {
        String s => '\'$s\'',
        num s => '$s',
        _ => throw 'Wrong type ($o)',
      };

  static String assoc(MP attr, String? pre) {
    return attr.entries.map((w) {
      String key = "${pre != null ? '`$pre`.' : ''}`${w.key}`";
      return switch (w.value) {
        List l => '$key IN(${l.map(
              (s) => _str(s),
            ).join(',')})',
        String s when s.isNotEmpty && s[0] == '%' => '$key LIKE ${_str(s)}',
        var s when s is String || s is num => '$key = ${_str(s)}',
        _ => '',
      };
    }).join(' AND ');
  }

  /*
  selectType(dynamic h) {
    final row = switch (h) {
      String s => select(
          limit: 1,
          subWhere: {
            'event': {'hash': s}
          },
        )[0]['type'],
      int i => i,
      _ => throw 'Wrong type ($h)',
    };
  }
  */

  String makeWhere(where, [String? pre]) => switch (where) {
        MP m => assoc(m, pre),
        List<MP> l => l.map((m) => '(${assoc(m, pre)})').join(' AND '),
        _ => '',
      };

  ResultSet select({
    Iterable<String>? fields,
    Map<String, Object?>? subWhere,
    //Object? where,
    int limit = 0,
    bool includeSubTypes = false,
  }) {
    //parents;
    final name = this.name;
    final q = <String>[
      "SELECT ${fields?.join(',') ?? '*'}, fractal.id AS id FROM $name",
    ];

    for (final ctrl in controllers) {
      final cname = ctrl.name;
      final w = subWhere?[cname];
      String sw = (w != null) ? makeWhere(w, cname) : '';
      q.add('''
        INNER JOIN $cname ON 
        $cname.id_fractal = $name.id_fractal
        ${sw.isNotEmpty ? 'AND $sw' : ''}
      ''');
    }

    final w = subWhere?['fractal'];
    String fw = (w != null)
        ? makeWhere(
            w,
            'fractal',
          )
        : '';

    q.add('''
      INNER JOIN fractal ON 
      $name.id_fractal = fractal.id
      ${fw.isNotEmpty ? 'AND $fw' : ''}
    ${includeSubTypes ? '' : "AND fractal.type = '$name'"}
    ''');

    final wh = subWhere?[name];
    String hw = (wh != null) ? makeWhere(wh, name) : '';
    if (hw.isNotEmpty) q.add('WHERE $hw');

    if (limit > 0) {
      q.add('''
        LIMIT $limit
      ''');
    }

    final query = q.join('\n');
    final rows = db.select(
      query,
    );

    return rows;
  }
}
