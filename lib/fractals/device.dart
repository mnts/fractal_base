import 'package:fractal/utils/random.dart';
import 'package:signed_fractal/signed_fractal.dart';

class DeviceCtrl<T extends DeviceFractal> extends NodeCtrl<T> {
  DeviceCtrl({
    super.name = 'device',
    required super.make,
    required super.extend,
    required super.attributes,
  });

  @override
  final icon = IconF(0xe471);
}

class DeviceFractal extends NodeFractal with SigningMix {
  static final active = Frac<DeviceFractal?>(null);

  static final controller = DeviceCtrl(
    make: (d) => switch (d) {
      MP() => DeviceFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
    attributes: [
      Attr(
        name: 'eth',
        format: 'TEXT',
        canNull: true,
      ),
      ...SigningMix.attributes,
    ],
    extend: NodeFractal.controller,
  );

  @override
  DeviceCtrl get ctrl => controller;

  static init() async {
    controller.init();
  }

  late final KeyPair keyPair;
  static late DeviceFractal my;

  String? eth;

  static final map = MapF<DeviceFractal>();

  DeviceFractal({
    this.eth,
    super.to,
    super.keyPair,
    super.extend,
    required super.name,
  }) : keyPair = SigningMix.signing() {
    map.complete(name, this);
  }

  DeviceFractal.fromMap(MP d)
      : eth = d['eth'],
        keyPair = SigningMix.signingFromMap(d),
        super.fromMap(d) {
    map.complete(name, this);
  }

  MP get _map => {
        'eth': eth,
        ...signingMap,
      };

  @override
  preload([type]) {
    if (type == 'node') {
      FileFractal.trace(
        FileF.path,
      );
    }
    return super.preload(type);
  }

  @override
  synch() {
    return super.synch();
  }

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };
}
