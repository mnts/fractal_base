import 'package:frac/frac.dart';

import '../db.dart';

class StoredFrac extends Frac<Object> {
  static final map = <String, StoredFrac>{};
  factory StoredFrac(
    String name,
    String iniVal,
  ) =>
      map[name] ??= StoredFrac._(name, iniVal);

  Future<void> setValue(val) async {
    await DBF.main.setVar(name, val);
    super.value = val;
  }

  String name;

  StoredFrac._(this.name, String iniVal) : super(iniVal) {}
}
