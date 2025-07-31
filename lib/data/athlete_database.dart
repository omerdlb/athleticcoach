import 'dart:async';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/data/models/recent_test_model.dart';
import 'package:athleticcoach/data/models/team_analysis_model.dart';
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
      version: 6,
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
            aiAnalysis TEXT,
            sessionId TEXT, -- yeni eklendi
            FOREIGN KEY (athleteId) REFERENCES athletes (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE recent_tests(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            testName TEXT,
            athleteName TEXT,
            testDate TEXT,
            viewedAt INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE team_analysis(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            testSessionId TEXT,
            testName TEXT,
            analysis TEXT,
            createdAt INTEGER,
            participantCount INTEGER
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
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE test_results ADD COLUMN aiAnalysis TEXT');
        }
        if (oldVersion < 4) {
          // Eğer aiAnalysis sütunu hala yoksa ekle
          try {
            await db.execute('ALTER TABLE test_results ADD COLUMN aiAnalysis TEXT');
          } catch (e) {
            // Sütun zaten varsa hata vermesin
          }
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE recent_tests(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              testName TEXT,
              athleteName TEXT,
              testDate TEXT,
              viewedAt INTEGER
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE team_analysis(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              testSessionId TEXT,
              testName TEXT,
              analysis TEXT,
              createdAt INTEGER,
              participantCount INTEGER
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE test_results ADD COLUMN sessionId TEXT');
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

  Future<void> updateTestResult(TestResultModel result) async {
    final db = await database;
    await db.update(
      'test_results',
      result.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  // Recent Tests CRUD operations
  Future<void> addRecentTest(RecentTestModel recentTest) async {
    final db = await database;
    
    // Önce aynı test varsa sil
    await db.delete(
      'recent_tests',
      where: 'testName = ? AND athleteName = ? AND testDate = ?',
      whereArgs: [recentTest.testName, recentTest.athleteName, recentTest.testDate],
    );
    
    // Yeni testi ekle
    await db.insert(
      'recent_tests',
      recentTest.toMap(),
    );
    
    // Sadece son 10 testi tut
    final allTests = await db.query(
      'recent_tests',
      orderBy: 'viewedAt DESC',
    );
    
    if (allTests.length > 10) {
      final testsToDelete = allTests.skip(10);
      for (final test in testsToDelete) {
        await db.delete(
          'recent_tests',
          where: 'id = ?',
          whereArgs: [test['id']],
        );
      }
    }
  }

  Future<List<RecentTestModel>> getRecentTests({int limit = 3}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recent_tests',
      orderBy: 'viewedAt DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return RecentTestModel.fromMap(maps[i]);
    });
  }

  Future<List<TestResultModel>> getRecentTestResults({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'test_results',
      orderBy: 'testDate DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return TestResultModel.fromMap(maps[i]);
    });
  }

  Future<void> clearRecentTests() async {
    final db = await database;
    await db.delete('recent_tests');
  }

  // Team Analysis CRUD operations
  Future<void> addTeamAnalysis(TeamAnalysisModel analysis) async {
    final db = await database;
    await db.insert(
      'team_analysis',
      analysis.toMap(),
    );
  }

  Future<TeamAnalysisModel?> getLatestTeamAnalysis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'team_analysis',
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return TeamAnalysisModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TeamAnalysisModel>> getAllTeamAnalysis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'team_analysis',
      orderBy: 'createdAt DESC',
    );
    
    return List.generate(maps.length, (i) {
      return TeamAnalysisModel.fromMap(maps[i]);
    });
  }

  Future<void> clearTeamAnalysis() async {
    final db = await database;
    await db.delete('team_analysis');
  }
} 