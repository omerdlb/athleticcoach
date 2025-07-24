import 'dart:async';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AthleteDatabase {
  static final AthleteDatabase _instance = AthleteDatabase._internal();
  factory AthleteDatabase() => _instance;
  AthleteDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'athletes.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE athletes(
            id TEXT PRIMARY KEY,
            name TEXT,
            surname TEXT,
            birthDate TEXT,
            gender TEXT,
            weight REAL,
            height REAL,
            branch TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE test_results(
            id TEXT PRIMARY KEY,
            testId TEXT,
            testName TEXT,
            athleteId TEXT,
            athleteName TEXT,
            athleteSurname TEXT,
            testDate TEXT,
            result REAL,
            resultUnit TEXT,
            notes TEXT,
            FOREIGN KEY (athleteId) REFERENCES athletes (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE test_results(
              id TEXT PRIMARY KEY,
              testId TEXT,
              testName TEXT,
              athleteId TEXT,
              athleteName TEXT,
              athleteSurname TEXT,
              testDate TEXT,
              result REAL,
              resultUnit TEXT,
              notes TEXT,
              FOREIGN KEY (athleteId) REFERENCES athletes (id)
            )
          ''');
        }
      },
    );
  }

  // Athlete CRUD operations
  Future<void> insertAthlete(AthleteModel athlete) async {
    final db = await database;
    await db.insert(
      'athletes',
      {
        'id': athlete.id,
        'name': athlete.name,
        'surname': athlete.surname,
        'birthDate': athlete.birthDate.toIso8601String(),
        'gender': athlete.gender,
        'weight': athlete.weight,
        'height': athlete.height,
        'branch': athlete.branch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAthlete(AthleteModel athlete) async {
    final db = await database;
    await db.update(
      'athletes',
      {
        'name': athlete.name,
        'surname': athlete.surname,
        'birthDate': athlete.birthDate.toIso8601String(),
        'gender': athlete.gender,
        'weight': athlete.weight,
        'height': athlete.height,
        'branch': athlete.branch,
      },
      where: 'id = ?',
      whereArgs: [athlete.id],
    );
  }

  Future<List<AthleteModel>> getAllAthletes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('athletes');
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return AthleteModel(
        id: map['id'],
        name: map['name'],
        surname: map['surname'],
        birthDate: DateTime.parse(map['birthDate']),
        gender: map['gender'],
        weight: map['weight'],
        height: map['height'],
        branch: map['branch'],
      );
    });
  }

  // Test Results CRUD operations
  Future<void> insertTestResult(TestResultModel result) async {
    final db = await database;
    await db.insert(
      'test_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TestResultModel>> getTestResultsByAthlete(String athleteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_results',
      where: 'athleteId = ?',
      whereArgs: [athleteId],
      orderBy: 'testDate DESC',
    );
    return List.generate(maps.length, (i) {
      return TestResultModel.fromMap(maps[i]);
    });
  }

  Future<List<TestResultModel>> getAllTestResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_results',
      orderBy: 'testDate DESC',
    );
    return List.generate(maps.length, (i) {
      return TestResultModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteTestResult(String resultId) async {
    final db = await database;
    await db.delete(
      'test_results',
      where: 'id = ?',
      whereArgs: [resultId],
    );
  }
} 