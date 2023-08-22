class Attr {
  final String name;
  final Type type;
  final String def;
  final bool isUnique;
  final bool isPrivate;

  String get sqlType => switch (type) {
        (int) => 'INTEGER',
        (double) => 'REAL',
        (String) => 'TEXT',
        (_) => throw Exception(
            'Unknown type',
          ),
      };

  String get sqlDefinition =>
      "'$name' $sqlType ${def.isNotEmpty ? 'DEFAULT $def ' : ''} ${isUnique ? 'UNIQUE' : ''} NOT NULL";

  @override
  String toString() => '$sqlDefinition ';

  const Attr(
    this.name,
    this.type, {
    this.isUnique = false,
    this.isPrivate = false,
    this.def = '',
  });
}
