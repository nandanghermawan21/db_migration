library db_migration;

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Databases {
  String dbName = "DataBase";
  String? dbMigrationAssets = "dbmigration";
  Database? db;
  int? version;

  // return the path
  Future<String> checkDb(String dbName, {bool deleteOldDb = false}) async {
    var databasePath = await getDatabasesPath();
    // print(databasePath);
    String path = join(databasePath, dbName);

    // make sure the folder exists
    if (await Directory(dirname(path)).exists()) {
      if (deleteOldDb) {
        await deleteDatabase(path);
      }
    } else {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        // ignore: use_rethrow_when_possible
        throw (e);
      }
    }
    return path;
  }

  Future<Databases> initializeDb({
    String? dbName,
    String? dbMigrationAssets,
    bool deleteOldDb = false,
    Function(Database?, int)? onCreate,
  }) async {
    String path =
        await checkDb(dbName ?? this.dbName, deleteOldDb: deleteOldDb);
    db = await openDatabase(path);
    db?.getVersion().then((version) {
      version = version;
      if (onCreate != null) {
        onCreate(db, version);
      }
    });
    db = db;
    return this;
  }

  Future<Database?> openConnection() async {
    String path = await checkDb(dbName);
    db = await openDatabase(path);
    db = db;
    return db;
  }

  Future<void> closeConnection() async {
    try {
      return db?.close().then((onValue) {
        return;
      }).catchError((onError) {
        throw onError;
      });
    } catch (e) {
      // ignore: use_rethrow_when_possible
      throw e;
    }
  }

  static Future<List<Map<String, Object?>>>? readSchema(Database? db) {
    String sql =
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
    return db?.rawQuery(sql);
  }

  Future<void> startMigration(int version) async {
    //read version tertinggi dari migration
    var latestVersion = 0;
    final migrationDir = await rootBundle.load('$dbMigrationAssets/');
    final migrationContent =
        String.fromCharCodes(migrationDir.buffer.asUint8List());

    final migrations = migrationContent.split('\n');
    for (final migration in migrations) {
      if (int.parse(migration.split('v').last) > latestVersion) {
        latestVersion = int.parse(migration.split('v').last);
      }
    }

    for (int i = version; i < latestVersion; i++) {
      rootBundle.loadString("dbmigration/dbv${i + 1}.sql").then((sql) {
        db?.execute(sql).then((v) {
          db?.setVersion(i + 1).then((v) {
            debugPrint("update to version ${i + 1}");
          });
        });
      });
      debugPrint("update is uptodate");
    }
  }
}
