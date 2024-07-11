import 'package:fractal/types/mp.dart';

abstract class FDBA {
  String name;
  FDBA(this.name);
  Future<bool> connect();
  Future<int> lastInsertId = Future.value(0);
  Future<int> store(FTransactionParams transaction);
  Future<bool> query(String sql, [List<Object?> parameters = const []]);
  Future<List<MP>> select(String sql, [List<Object?> parameters = const []]);
}

class FStatementParams {
  final String sql;
  final List<Object?> parameters;

  const FStatementParams(this.sql, this.parameters);
}

class FTransactionParams {
  final List<FStatementParams> statements;

  const FTransactionParams(this.statements);
}
