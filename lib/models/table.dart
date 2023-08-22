import 'attr.dart';

class TableF {
  final String name;
  List<Attr> attributes;

  TableF({
    required this.name,
    this.attributes = const [],
  }) {
    print('table $name');
  }

  static final map = <String, TableF>{};
}
