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
  final bool isReference;
  final bool canNull;
  final bool skipCreate;

  /*
  String get sqlType => switch (type) {
        (int) => 'INTEGER',
        (double) => 'REAL',
        (String) => 'TEXT',
        (List) => 'BLOB',
        (_) => throw Exception(
            'Unknown type',
          ),
      };
      */

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
    this.isReference = false,
    this.skipCreate = false,
    this.options = const [],
    this.def = '',
    super.kind = FKind.eternal,
    super.to,
  }) {
    //owner = null;
    //hash = Hashed.make(ctrl.hashData());
  }

  Attr.fromMap(super.d)
      : format = d['format'],
        def = "${d['def'] ?? ''}",
        isUnique = d['isUnique'] ?? false,
        skipCreate = d['skipCreate'] ?? false,
        isIndex = d['isIndex'] ?? false,
        options = d['options'] ?? [],
        isPrivate = d['isPrivate'] ?? false,
        isReference = d['isReference'] ?? false,
        isImmutable = d['isImmutable'] ?? false,
        canNull = d['canNull'] ?? false,
        super.fromMap();

  @override
  Object? operator [](String key) => switch (key) {
        'format' => format,
        'widget' => super[key] ?? 'input',
        'def' => def,
        'isUnique' => isUnique,
        'skipCreate' => skipCreate,
        'isIndex' => isIndex,
        'options' => options,
        'isPrivate' => isPrivate,
        'isImmutable' => isImmutable,
        'canNull' => canNull,
        _ => super[key],
      };
}
