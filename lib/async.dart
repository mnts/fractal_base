import 'dart:isolate';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:sqlite3/common.dart';

import 'access/unsupported.dart'
    if (dart.library.ffi) 'access/fs.dart'
    if (dart.library.html) 'access/web.dart';
import 'access/abstract.dart';

class AsyncDatabase {
  static final Logger _log = Logger((AsyncDatabase).toString());

  final Isolate _worker;
  final SendPort _workerPort;

  AsyncDatabase._(this._worker, this._workerPort);

  /// Opens a database file.
  ///
  /// The [vfs] option can be used to set the appropriate virtual file system
  /// implementation. When null, the default file system will be used.
  ///
  /// If [uri] is enabled (defaults to `false`), the [filename] will be
  /// interpreted as an uri as according to https://www.sqlite.org/uri.html.
  ///
  /// If the [mutex] parameter is set to true, the `SQLITE_OPEN_FULLMUTEX` flag
  /// will be set. If it's set to false, `SQLITE_OPEN_NOMUTEX` will be enabled.
  /// By default, neither parameter will be set.
  static Future<AsyncDatabase> open(
    String filename, {
    String? vfs,
    OpenMode mode = OpenMode.readWriteCreate,
    bool uri = false,
    bool? mutex,
  }) async {
    PrintAppender.setupLogging(level: Level.INFO);

    var receivePort = ReceivePort();
    //var token = RootIsolateToken.instance;
    var worker = await Isolate.spawn(
        _executeCommand,
        AsyncDatabaseCommand(
          "_init",
          receivePort.sendPort,
        ));

    AsyncDatabaseCommand response = await receivePort.first;
    var workerPort = response.sendPort;
    var asyncDatabase = AsyncDatabase._(worker, workerPort);
    await asyncDatabase.sendCommand("open",
        body: OpenDatabaseParams(filename, vfs, mode, uri, mutex));
    return asyncDatabase;
  }

  /// Returns the application defined version of this database.
  Future<int> getUserVersion() async {
    return await sendCommand("getUserVersion");
  }

  /// Set the application defined version of this database.
  Future<void> setUserVersion(int value) async {
    await sendCommand("setUserVersion", body: value);
  }

  /// Returns the row id of the last inserted row.
  Future<int> getLastInsertRowId() async {
    return await sendCommand("getLastInsertRowId");
  }

  /// Executes the [sql] statement with the provided [parameters] and ignores
  /// the result.
  Future<void> execute(String sql,
      [List<Object?> parameters = const []]) async {
    await sendCommand("execute", body: FStatementParams(sql, parameters));
  }

  Future<void> transaction(FTransactionParams transaction) async {
    await sendCommand("transaction", body: transaction);
  }

  /// Prepares the [sql] select statement and runs it with the provided
  /// [parameters].
  Future<ResultSet> select(String sql,
      [List<Object?> parameters = const []]) async {
    return await sendCommand("select", body: FStatementParams(sql, parameters));
  }

  /// Closes this database and releases associated resources.
  Future<void> dispose() async {
    await sendCommand("dispose");
    _worker.kill();
  }

  static void _executeCommand(AsyncDatabaseCommand initCmd) async {
    var ourReceivePort = ReceivePort();
    assert(initCmd.type == "_init");
    //BackgroundIsolateBinaryMessenger.ensureInitialized(initCmd.body);
    initCmd.sendPort
        .send(AsyncDatabaseCommand(initCmd.type, ourReceivePort.sendPort));

    CommonDatabase? db;
    await for (AsyncDatabaseCommand cmd in ourReceivePort) {
      try {
        switch (cmd.type) {
          case "open":
            db = await openDBSync(cmd, ourReceivePort);
            break;
          case "getUserVersion":
            _getUserVersionSync(db!, cmd, ourReceivePort);
            break;
          case "setUserVersion":
            _setUserVersionSync(db!, cmd, ourReceivePort);
            break;
          case "getLastInsertRowId":
            _getLastInsertRowIdSync(db!, cmd, ourReceivePort);
            break;
          case "execute":
            _executeSync(db!, cmd, ourReceivePort);
          case 'store':
            _store(db!, cmd, ourReceivePort);
          case "transaction":
            _transaction(db!, cmd, ourReceivePort);
            break;
          case "select":
            _selectSync(db!, cmd, ourReceivePort);
            break;
          case "dispose":
            _disposeSync(db!, cmd, ourReceivePort);
            break;
          default:
            throw Exception("Unknown command type. type=${cmd.type}");
        }
      } catch (e, s) {
        _log.severe("Could not execute Sqlite command", e, s);
        cmd.sendPort.send(AsyncDatabaseCommand(
            cmd.type, ourReceivePort.sendPort,
            body: e, isError: true));
      }
    }
  }

  static void _disposeSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    db.dispose();
    cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
    ourReceivePort.close();
  }

  static void _selectSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    FStatementParams params = cmd.body;
    var response = db.select(params.sql, params.parameters);
    cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort,
        body: response));
  }

  static void _executeSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    FStatementParams params = cmd.body;
    db.execute(params.sql, params.parameters);
    cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
  }

  static void _store(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    FTransactionParams params = cmd.body;

    int id = 0;
    try {
      db.execute('BEGIN;');
      final st = params.statements.removeAt(0);
      db.execute(st.sql, st.parameters);
      id = db.lastInsertRowId;
      for (var st in params.statements) {
        db.execute(st.sql, [...st.parameters, id]);
      }
      db.execute("COMMIT;");
    } catch (err) {
      print(err);
      db.execute("END;");
    }
    cmd.sendPort.send(AsyncDatabaseCommand(
      cmd.type,
      ourReceivePort.sendPort,
      body: id,
    ));
  }

  static void _transaction(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    FTransactionParams params = cmd.body;

    try {
      db.execute('BEGIN;');
      for (var st in params.statements) {
        db.execute(st.sql, st.parameters);
      }
      db.execute("COMMIT;");
    } catch (err) {
      print(err);
      db.execute("END;");
    }
    cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
  }

  Future<dynamic> sendCommand(String type, {dynamic body}) async {
    var receivePort = ReceivePort();
    var command = AsyncDatabaseCommand(type, receivePort.sendPort, body: body);
    _workerPort.send(command);
    AsyncDatabaseCommand response = await receivePort.first;
    if (response.isError) {
      throw response.body;
    }
    return response.body;
  }

  static void _getLastInsertRowIdSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    var rowId = db.lastInsertRowId;
    cmd.sendPort.send(
        AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort, body: rowId));
  }

  static void _setUserVersionSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    db.userVersion = cmd.body;
    cmd.sendPort.send(AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort));
  }

  static void _getUserVersionSync(
      CommonDatabase db, AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) {
    var version = db.userVersion;
    cmd.sendPort.send(
        AsyncDatabaseCommand(cmd.type, ourReceivePort.sendPort, body: version));
  }
}

class AsyncDatabaseCommand {
  final String type;
  final SendPort sendPort;
  final dynamic body;
  final bool isError;

  const AsyncDatabaseCommand(this.type, this.sendPort,
      {this.body, this.isError = false});
}

class OpenDatabaseParams {
  final String filename;
  final String? vfs;
  final OpenMode mode;
  final bool uri;
  final bool? mutex;

  const OpenDatabaseParams(
      this.filename, this.vfs, this.mode, this.uri, this.mutex);
}
