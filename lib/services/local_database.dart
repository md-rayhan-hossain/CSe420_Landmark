import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/models/visit_record.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase({
    String? databasePath,
    DatabaseFactory? databaseFactoryOverride,
  })  : _databasePath = databasePath,
        _databaseFactory = databaseFactoryOverride;

  static const _databaseName = 'smart_geo_landmarks.db';
  static const _databaseVersion = 1;

  final String? _databasePath;
  final DatabaseFactory? _databaseFactory;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final factory = _databaseFactory ?? databaseFactory;
    final dbPath =
        _databasePath ?? path.join(await getDatabasesPath(), _databaseName);
    _database = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _createSchema,
      ),
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE landmarks (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        image TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        visit_count INTEGER NOT NULL DEFAULT 0,
        avg_distance REAL NOT NULL DEFAULT 0,
        score REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER NOT NULL,
        landmark_title TEXT NOT NULL,
        user_lat REAL NOT NULL,
        user_lon REAL NOT NULL,
        visited_at TEXT NOT NULL,
        distance_meters REAL,
        status TEXT NOT NULL,
        error_message TEXT
      )
    ''');
  }

  Future<void> saveLandmarks(List<Landmark> landmarks) async {
    final db = await database;
    final batch = db.batch();
    for (final landmark in landmarks) {
      if (landmark.id == null) continue;
      batch.insert(
        'landmarks',
        landmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Landmark>> getLandmarks({bool activeOnly = false}) async {
    final db = await database;
    final rows = await db.query(
      'landmarks',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows
        .map(Landmark.fromMap)
        .where((landmark) => landmark.canUseInApp)
        .toList();
  }

  Future<List<Landmark>> getDeletedLandmarks() async {
    final db = await database;
    final rows = await db.query(
      'landmarks',
      where: 'is_active = ?',
      whereArgs: [0],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows
        .map(Landmark.fromMap)
        .where((landmark) => landmark.canUseInApp)
        .toList();
  }

  Future<void> markLandmarkActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      'landmarks',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertVisit(VisitRecord visit) async {
    final db = await database;
    return db.insert('visits', visit.toMap()..remove('id'));
  }

  Future<void> updateVisit(VisitRecord visit) async {
    if (visit.id == null) return;
    final db = await database;
    await db.update(
      'visits',
      visit.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<List<VisitRecord>> getVisits() async {
    final db = await database;
    final rows =
        await db.query('visits', orderBy: 'datetime(visited_at) DESC, id DESC');
    return rows.map(VisitRecord.fromMap).toList();
  }

  Future<List<VisitRecord>> getPendingVisits() async {
    final db = await database;
    final rows = await db.query(
      'visits',
      where: 'status = ? OR status = ?',
      whereArgs: [VisitStatus.pending, VisitStatus.failed],
      orderBy: 'datetime(visited_at) ASC, id ASC',
    );
    return rows.map(VisitRecord.fromMap).toList();
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
