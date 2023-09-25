import 'attr.dart';

class TableF {
  final String name;
  List<Attr> attributes;

  TableF({
    required this.name,
    this.attributes = const [],
  }) {}

  static final map = <String, TableF>{};
}
