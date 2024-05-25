import 'dart:isolate';

import 'package:sqlite3/common.dart';

import '../async.dart';

Future<CommonDatabase> openDBSync(
        AsyncDatabaseCommand cmd, ReceivePort ourReceivePort) =>
    throw UnimplementedError();
