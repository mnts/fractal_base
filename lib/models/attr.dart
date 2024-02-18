import 'package:signed_fractal/signed_fractal.dart';

class AttrCtrl<T extends Attr> extends NodeCtrl<T> {
  AttrCtrl({
    super.name = 'attribute',
    required super.make,
    required super.extend,
    required super.attributes,
  });

  @override
  final icon = IconF(0xf0a2);
}

class Attr extends NodeFractal {
  static final controller = AttrCtrl(
      extend: NodeFractal.controller,
      make: (d) => switch (d) {
            MP() => Attr.fromMap(d),
            _ => throw ('wrong'),
          },
      attributes: <Attr>[
        Attr(
          name: 'filter',
          format: 'TEXT',
        ),
        Attr(
          name: 'source',
          format: 'TEXT',
        ),
      ]);

  @override
  AttrCtrl get ctrl => controller;

  @override
  get hashData => [...super.hashData, format];
  @override
  String get type => 'attribute';

  final String format;
  final String def;
  final bool isUnique;
  final bool isPrivate;
  final bool canNull;

  String get sqlType => switch (type) {
        (int) => 'INTEGER',
        (double) => 'REAL',
        (String) => 'TEXT',
        (List) => 'BLOB',
        (_) => throw Exception(
            'Unknown type',
          ),
      };

  String get sqlDefinition =>
      "'$name' $format ${def.isNotEmpty ? 'DEFAULT $def ' : ''} ${isUnique ? 'UNIQUE' : ''} ${canNull ? ' ' : 'NOT '}NULL";

  @override
  String toString() => '$sqlDefinition ';

  Attr({
    required super.name,
    required this.format,
    this.isUnique = false,
    this.isPrivate = false,
    this.canNull = false,
    this.def = '',
    super.to,
  }) {
    createdAt = 1;
    //owner = null;
    hash = Hashed.makeHash(hashData);
  }

  Attr.fromMap(super.d)
      : format = d['format'],
        def = d['def'],
        isUnique = d['isUnique'],
        isPrivate = d['isPrivate'],
        canNull = d['canNull'],
        super.fromMap();

  @override
  Object? operator [](String key) => switch (key) {
        'format' => format,
        'widget' => 'input',
        _ => super[key],
      };
}
