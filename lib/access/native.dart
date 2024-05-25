import 'dart:async';
import 'package:fractal/fractal.dart';
import 'package:path/path.dart';
import '../async.dart';
import 'abstract.dart';

class NativeFDB extends FDBA {
  late AsyncDatabase _db;

  NativeFDB(super.name);

  @override
  Future connect() async {
    _db = await AsyncDatabase.open(
      join(FileF.path, "$name.db"),
    );
    return true;
  }

  @override
  query(String sql, [List<Object?> parameters = const []]) async {
    await _db.execute(sql, parameters);
    //_db.writeTransaction((tx) => null)
    return true;
  }

  @override
  Future store(FTransactionParams transaction) =>
      _db.sendCommand("store", body: transaction);

  @override
  select(String sql, [List<Object?> parameters = const []]) {
    return _db.select(sql, parameters);
  }

  @override
  Future<int> get lastInsertId async => _db.getLastInsertRowId();
}

FDBA constructDb(String name) {
  return NativeFDB(name);
}

/*
class NativeDBWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  static Future<NativeDBWorker> spawn() async {
    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };
    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return NativeDBWorker._(
      receivePort,
      sendPort,
    );
  }

  static void _startRemoteIsolate(SendPort port) {
    final receivePort = ReceivePort();
    port.send(receivePort.sendPort);

    receivePort.listen((dynamic message) async {
      if (message is String) {
        final transformed = jsonDecode(message);
        port.send(transformed);
      }
    });
  }

  NativeDBWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }
  bool _closed = false;

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      print('--- port closed --- ');
    }
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?); // New
    final completer = _activeRequests.remove(id)!; // New

    if (response is RemoteError) {
      completer.completeError(response); // Updated
    } else {
      completer.complete(response); // Updated
    }
  }
}
*/

/// An opened sqlite3 database with async methods.
