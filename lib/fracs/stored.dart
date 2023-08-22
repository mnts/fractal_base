import 'package:frac/frac.dart';

import '../db.dart';

class StoredFrac extends Frac<Object> {
  static final map = <String, StoredFrac>{};
  factory StoredFrac(
    String name,
    String iniVal,
  ) =>
      map[name] ??= StoredFrac._(name, iniVal);

  @override
  set value(val) {
    DBF.main[name] = val;
  }

  String name;

  StoredFrac._(this.name, String iniVal) : super(iniVal) {}
}
