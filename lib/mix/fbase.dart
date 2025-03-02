import '../access/abstract.dart';
import 'package:fractal/fractal.dart';

mixin StoredFract on Fractal {
  FDBA get db => DBF.main.db;

  String get tableName => '';
}
