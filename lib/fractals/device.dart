import 'package:signed_fractal/signed_fractal.dart';

class DeviceCtrl<T extends DeviceFractal> extends NodeCtrl<T> {
  DeviceCtrl({
    super.name = 'device',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'eth',
        String,
        canNull: true,
      ),
      ...SigningMix.attributes,
    ],
  });

  @override
  final icon = IconF(0xe481);
}

class DeviceFractal extends NodeFractal with SigningMix {
  static final active = Frac<DeviceFractal?>(null);

  static final controller = DeviceCtrl(
    make: (d) => switch (d) {
      MP() => DeviceFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
    extend: NodeFractal.controller,
  );

  @override
  DeviceCtrl get ctrl => controller;

  String? eth;

  static final map = MapF<DeviceFractal>();

  DeviceFractal({
    this.eth,
    super.to,
    super.keyPair,
    super.extend,
    required super.name,
  }) {
    signing();

    map.complete(name, this);
  }

  @override
  get hashData => [
        ...super.hashData,
      ];

  DeviceFractal.fromMap(MP d)
      : eth = d['eth'],
        super.fromMap(d) {
    signingFromMap(d);
    map.complete(name, this);
  }

  MP get _map => {
        'eth': eth,
        ...signingMap,
      };

  synch() {
    super.synch();
  }

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };
}
