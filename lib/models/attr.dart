class Attr {
  final String name;
  final Type type;
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
      "'$name' $sqlType ${def.isNotEmpty ? 'DEFAULT $def ' : ''} ${isUnique ? 'UNIQUE' : ''} ${canNull ? ' ' : 'NOT '}NULL";

  @override
  String toString() => '$sqlDefinition ';

  const Attr(
    this.name,
    this.type, {
    this.isUnique = false,
    this.isPrivate = false,
    this.canNull = false,
    this.def = '',
  });
}
