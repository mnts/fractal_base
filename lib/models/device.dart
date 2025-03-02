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
    make: (d) => DeviceFractal.fromMap(d),
    attributes: [
      Attr(
        name: 'eth',
        format: FormatF.text,
        canNull: true,
      ),
      ...SigningMix.attributes,
    ],
    extend: NodeFractal.controller,
  );

  @override
  DeviceCtrl get ctrl => controller;

  static Future init() async {
    await controller.init();
    return;
  }

  static Future<DeviceFractal> initMy() async {
    var name = (await DBF.main.getVar('device'));
    if (name == null) {
      name = getRandomString(8);
      await DBF.main.setVar('device', name);
    }

    final map = EventFractal.map.map;

    map['device'] = DeviceFractal.my = await DeviceFractal.controller.put({
      'name': name,
      'kind': FKind.eternal.index,
      'folder': FileF.path,
      'pubkey': '',
      'sync_at': 1,
    });
    await DeviceFractal.my.synch();
    return DeviceFractal.my;
  }

  late final KeyPair keyPair;
  static late DeviceFractal my;

  String? eth;

  static final map = MapEvF<DeviceFractal>();

  DeviceFractal({
    this.eth,
    super.to,
    super.keyPair,
    super.extend,
    required super.name,
  }) : keyPair = SigningMix.signing() {
    map.complete(name, this);
  }

  DeviceFractal.fromMap(super.d)
      : eth = d['eth'],
        keyPair = SigningMix.signingFromMap(d),
        super.fromMap() {
    map.complete(name, this);
  }

  MP get _map => {
        'eth': eth,
        ...signingMap,
      };

  @override
  int get decideSync => 2;

  @override
  preload([type]) {
    /*
    if (type == 'node') {
      FileFractal.trace(
        FileF.path,
      );
    }
    */

    return super.preload(type);
  }
}
