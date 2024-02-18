import 'package:fractal/c.dart';
import 'package:fractal/lib.dart';
import 'package:sqlite3/common.dart';

import '../db.dart';

extension FractalStoredC on FractalC {
  DBF get dbf => DBF.main;
  CommonDatabase get db => dbf.db;

  void query(String sql, [List<Object?> parameters = const []]) {
    db.execute(sql, parameters);
  }

  CommonPreparedStatement prepare(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    //print('prepare');
    //print(sql);
    return db.prepare(sql);
  }
}
