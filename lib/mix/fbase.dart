import 'package:sqlite3/common.dart';

import '../db.dart';
import 'package:fractal/fractal.dart';

mixin StoredFract on Fractal {
  CommonDatabase get db => DBF.main.db;

  String get tableName => '';
}
