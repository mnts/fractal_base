import 'dart:math';
import 'package:fractal/fractal.dart';

import '../access/abstract.dart';

extension SqlFractalExt on FractalCtrl {
  Future<TableF> initSql() async {
    for (var t in dbf.tables) {
      if (t.name == name) {
        await _columns();
        return t;
      }
    }

    return await _initTable();
/*
dbf.tables.firstWhere(
        (t) {
          final found = t.name == name;
          if (found) _columns();
          return found;
        },
        orElse: () => _initTable(),
      );
  */
  }

  //_columns();

  Future<void> initIndexes() async {
    final pragma = await db.select('''
      PRAGMA index_list(`$name`)
    ''');
    final cols = pragma.map((row) => row[1]);
    for (var attr in attributes) {
      final idxName = '${name}_${attr.name}';
      if (attr.isIndex && !cols.contains(idxName)) {
        await query(
          'CREATE ${attr.isUnique ? 'UNIQUE' : ''} INDEX `$idxName` ON `$name`(`${attr.name}`)',
        );

        print('attr: $idxName is now index');
      }
    }
  }

  static init() {}

  List listValues(MP map) => attributes
      .map(
        (attr) => map[attr.name],
      )
      .toList();

  //static int fid = 0;
  Future<int> store(MP map) async {
    //print(map);

    map['id'] = await db.lastInsertId;
    final transaction = FTransactionParams([
      _insertion(
        Fractal.controller,
        Fractal.controller.listValues(map),
      ),
      ...controllers.reversed.map(
        (ctrl) => _insertion(
          ctrl,
          ctrl.listValues(map),
        ),
      ),
      _insertion(this, listValues(map)),
    ]);

    final id = await db.store(transaction);
    print('store $name');
    print(map);
    print('#$id');
    return id;

    //'INSERT INTO $name (${map.keys.join(',')}) VALUES (${map.keys.map((e) => '?').join(',')}) ON CONFLICT(id) DO UPDATE SET ${map.keys.map((e) => '$e=?').join(',')}',
    /*
    print(
      '$name#$fid stored ${ctrls.map((c) => c.attributes.map((a) => a.name).join(',')).join(';')}',
    );
    print(map);
    */
  }

  bool get _isMain => runtimeType == FractalCtrl;

  FStatementParams _insertion(FractalCtrl c, List<Object?> list) {
    final ins = <(String, Object)>[];
    for (int i = 0; i < c.attributes.length; i++) {
      final attr = c.attributes[i];
      if (list[i] != null && !attr.skipCreate) {
        ins.add((attr.name, list[i]!));
      }
    }

    if (!c._isMain) ins.add(('id', ''));

    return FStatementParams(
        """
INSERT INTO `${c.name}` (
  ${ins.map((attr) => "'${attr.$1}'").join(',')}
) 
VALUES (
  ${ins.map((e) => '?').join(',')}
);
  """,
        ins
            .sublist(0, ins.length + ((c._isMain) ? 0 : -1))
            .map((i) => i.$2)
            .toList());
  }

  Future<TableF> _initTable() async {
    final fk = await db.select('''
      PRAGMA foreign_keys;
    ''');

    final defs = <String>[
      "id INTEGER PRIMARY KEY",
      for (var a in attributes.where((f) => !f.skipCreate)) a.sqlDefinition,
      if (runtimeType != FractalCtrl)
        //'id_fractal' INTEGER NOT NULL,
        """
      FOREIGN KEY(id) REFERENCES fractal(id) ON DELETE CASCADE
      """,
      /*
      for (var a in attributes.where((f) => f.format == FormatF.reference))
        "FOREIGN KEY(`${a.name}`) REFERENCES fractal(id) ON DELETE CASCADE"
      */
    ];

    //_columns();

    //final ctrl = controllers.firstOrNull;
    await query("CREATE TABLE IF NOT EXISTS `$name` (${defs.join(',\n')})");
    print('Create table `$name`');
    return TableF(
      name: name,
      attributes: attributes,
    );
    //${ctrl != null ? ",'id_${ctrl.name}' INTEGER NOT NULL" : ''}
  }

  Future<bool> _columns() async {
    final pragma = await db.select('''
      PRAGMA table_info(`$name`)
    ''');
    final cols = pragma.map((row) => row[1]);
    for (var attr in attributes) {
      if (!cols.contains(attr.name)) {
        _addColumn(attr);
      }
    }
    return true;
  }

  Future<bool> _addColumn(Attr attr) async {
    return await query('ALTER TABLE `$name` ADD ${attr.sqlDefinition}');
  }

  _removeTable() {
    dbf.db.query('''
      DROP TABLE IF EXISTS `$name`
    ''');
  }

  from() {}

  static String _str(Object o) => switch (o) {
        String s => '\'$s\'',
        num s => '$s',
        _ => throw 'Wrong type ($o)',
      };

  String assoc(MP attr) {
    final pre = name;
    return attr.entries.map((w) {
      String key = "`$pre`.`${w.key}`";
      final attr = attributes.firstWhere((a) => a.name == w.key);
      return switch (w.value) {
        Iterable l => '$key IN(${l.map(
              (s) => _str(s),
            ).join(',')})',
        Map m => m.entries
            .map((e) => switch (e.key) {
                  'gt' => '$key > ${_str(e.value)}',
                  'gte' => '$key >= ${_str(e.value)}',
                  'lt' => '$key < ${_str(e.value)}',
                  'lte' => '$key <= ${_str(e.value)}',
                  'in' => '$key IN(${e.value.map(
                        (s) => _str(s),
                      ).join(',')})',
                  'nin' => '$key NOT IN(${e.value.map(
                        (s) => _str(s),
                      ).join(',')})',
                  _ => '',
                })
            .join(' AND '),
        bool b => switch (attr.format) {
            'TEXT' => "$key ${b ? '!' : ''}= ''",
            _ => '$key IS ${b ? 'NOT ' : ''}NULL',
          },
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

  static String makeWhere(where, FractalCtrl ctrl) => switch (where) {
        MP m => ctrl.assoc(m),
        List<MP> l => l.map((m) => '(${ctrl.assoc(m)})').join(' AND '),
        _ => '',
      };

  Future<bool> update(MP m, int id) async {
    await query(
      'UPDATE `$name` SET ${m.keys.map((e) => '$e = ?').join(',')} WHERE id=?',
      [...m.values, id],
    );
    return true;
  }

  Future<List<MP>> select({
    Iterable<String>? fields,
    //Map<String, Object?>? subWhere,
    MP? where,
    int limit = 1200,
    Map<String, dynamic> order = const {'created_at': true},
    String group = '',
  }) {
    //parents;
    final MP w = {
      ...?where,
    };

    final name = this.name;
    final q = <String>[
      "SELECT ${fields?.join(',') ?? '*'}, fractal.id AS id FROM `$name`",
    ];

    for (final ctrl in [...controllers, Fractal.controller]) {
      MP tableWhere = {};
      w.removeWhere((key, value) {
        if (ctrl.attributes.any((attr) => attr.name == key)) {
          tableWhere[key] = value;
          return true;
        }
        return false;
      });

      String sw = (tableWhere.entries.isNotEmpty)
          ? makeWhere(
              tableWhere,
              ctrl,
            )
          : '';
      q.add('''
        INNER JOIN `${ctrl.name}` ON 
        `${ctrl.name}`.id = `$name`.id
        ${sw.isNotEmpty ? 'AND $sw' : ''}
      ''');
    }

    /*
    String fw = '';
    if (w.remove('id') case Object idv) {
      fw = makeWhere(
        {'id': idv},
        Fractal.controller,
      );
    }

    if (w.isNotEmpty == true) {
      w.removeWhere((key, value) {
        q.add('''
        INNER JOIN `event` AS `attr_event` ON 
        `attr_event`.`to` = `event`.`hash`
        INNER JOIN `writer` `attr_writer` ON 
        `attr_writer`.attr = '$key'
        INNER JOIN `post` `attr_post` ON 
        `attr_post`.`content` ${switch (value) {
          String s => "= '$s'",
          false => "= ''",
          _ => "!= ''",
        }}
        ''');
        return true;
      });
    }

    q.add('''
      INNER JOIN fractal ON 
      `$name`.id_fractal = fractal.id
      ${fw.isNotEmpty ? 'AND $fw' : ''}
      ${includeSubTypes ? '' : "AND fractal.type = '$name'"}
    ''');
    */

    if (w.entries.isNotEmpty) {
      final wH = makeWhere(w, this);
      if (wH.isNotEmpty) q.add('WHERE $wH');
    }

    limit = limit > 0 ? min(limit, maxLimit) : maxLimit;

    if (order.isNotEmpty) {
      q.add('ORDER BY');
      order.forEach((key, v) {
        q.add('`$key` ${v ? 'DESC' : 'ASC'}');
      });
    }

    if (group.isNotEmpty) {
      q.add('GROUP BY');
      order.forEach((key, v) {
        q.add('`$group`');
      });
    }

    q.add('''
        LIMIT $limit
      ''');

    final query = q.join('\n');
    //print(query.replaceAll("\n", " "));
    return db.select(
      query,
    );
  }

  static const maxLimit = 1000;
}
