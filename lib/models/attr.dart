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
          name: 'format',
          format: 'TEXT',
        ),
      ]);

  @override
  AttrCtrl get ctrl => controller;

  @override
  String get type => 'attribute';

  final String format;
  final String def;
  final bool isImmutable;
  final bool isUnique;
  final bool isIndex;
  final bool isPrivate;
  final bool canNull;
  final bool skipCreate;

  String get sqlType => switch (type) {
        (int) => 'INTEGER',
        (double) => 'REAL',
        (String) => 'TEXT',
        (List) => 'BLOB',
        (_) => throw Exception(
            'Unknown type',
          ),
      };

  Object fromString(String val) => switch (format) {
        'INTEGER' => int.parse(val),
        'REAL' => double.parse(val),
        _ => val,
      };

  String get sqlDefinition =>
      "'$name' $format ${!canNull ? 'DEFAULT \'$def\' ' : ''} ${isUnique ? 'UNIQUE' : ''} ${canNull ? ' ' : 'NOT '}NULL";

  @override
  String toString() => '$sqlDefinition ';

  final List<String> options;

  Attr({
    required super.name,
    required this.format,
    this.isUnique = false,
    this.isIndex = false,
    this.isPrivate = false,
    this.canNull = false,
    this.isImmutable = false,
    this.skipCreate = false,
    this.options = const [],
    this.def = '',
    super.createdAt = 2,
    super.to,
  }) {
    //owner = null;
    //hash = Hashed.make(ctrl.hashData());
  }

  Attr.fromMap(super.d)
      : format = d['format'],
        def = d['def'],
        isUnique = d['isUnique'],
        skipCreate = d['skipCreate'],
        isIndex = d['isIndex'],
        options = d['options'] ?? [],
        isPrivate = d['isPrivate'],
        isImmutable = d['isImmutable'],
        canNull = d['canNull'],
        super.fromMap();

  @override
  MP toMap() => {
        ...super.toMap(),
        for (var a in ctrl.attributes) a.name: this[a.name],
      };

  @override
  Object? operator [](String key) => switch (key) {
        'format' => format,
        'widget' => 'input',
        _ => super[key],
      };
}
