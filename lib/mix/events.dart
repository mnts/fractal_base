import 'package:signed_fractal/signed_fractal.dart';

/*
mixin FractalBaseCtrl<T extends EventFractal> on FractalCtrl {
  Future<List<T>> collect(Iterable<int> ids) async {
    final res = await select(
      where: {'id': ids},
    );

    final fractals = <T>[];
    for (MP item in res) {
      final f = await put({
        ...item,
      });
      fractals.add(f);
    }
    return fractals;
  }
}
*/