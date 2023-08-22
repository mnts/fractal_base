import 'package:fractal/lib.dart';
import 'package:fractal_base/extensions/stored.dart';

extension FractalBaseExt on Fractal {
  update(MP m) {
    query(
      'UPDATE ${ctrl.name} SET ${m.keys.map((e) => '$e = ?').join(',')} WHERE id=?',
      [...m.values, id],
    );
  }
}
