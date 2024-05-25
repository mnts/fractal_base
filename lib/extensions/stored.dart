import 'package:fractal/c.dart';
import 'package:fractal/lib.dart';
import 'package:sqlite3/common.dart';

import '../access/abstract.dart';
import '../db.dart';

extension FractalStoredC on FractalC {
  DBF get dbf => DBF.main;
  FDBA get db => dbf.db;

  Future<bool> query(String sql, [List<Object?> parameters = const []]) =>
      db.query(sql, parameters);

  /*
  CommonPreparedStatement prepare(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    //print('prepare');
    //print(sql);
    return db.prepare(sql);
  }
  */
}
