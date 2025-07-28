import 'dart:async';

import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 20 m Multistage Fitness Test (Beep Test)
/// Kaynak: https://www.topendsports.com/testing/tests/20mshuttle.htm
class BeepTestScreen extends StatefulWidget {
  const BeepTestScreen({super.key});

  @override
  State<BeepTestScreen> createState() => _BeepTestScreenState();
}

class _BeepTestScreenState extends State<BeepTestScreen> {
  final _db = AthleteDatabase();
  final _beepPlayer = AudioPlayer();

  // Test state
  bool _isRunning = false;
  bool _isPaused = false;
  int _currentLevel = 1;
  int _currentShuttle = 0;
  int _elapsedSeconds = 0;
  int _levelStartTime = 0;

  // Timers
  Timer? _beepTimer;
  Timer? _testTimer;

  // Athletes
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  List<AthleteModel> _active = [];
  Map<String, int> _warnings = {}; // athleteId -> warnings
  Map<String, bool> _failed = {}; // athleteId -> eliminated
  Map<String, int> _athleteLevels = {}; // athleteId -> level
  Map<String, int> _athleteShuttles = {}; // athleteId -> shuttle
  Map<String, int> _athleteDistances = {}; // athleteId -> distance in meters

  // Level -> required shuttle count (Australian beep-test standard)
  // Her seviye 1 dakika sürer, şutle sayısı hız artışına göre değişir
  final Map<int, int> _levelShuttles = {
    1: 7,   // 8.5 km/h
    2: 8,   // 9.0 km/h  
    3: 8,   // 9.5 km/h
    4: 9,   // 10.0 km/h
    5: 9,   // 10.5 km/h
    6: 10,  // 11.0 km/h
    7: 10,  // 11.5 km/h
    8: 11,  // 12.0 km/h
    9: 11,  // 12.5 km/h
    10: 12, // 13.0 km/h
    11: 12, // 13.5 km/h
    12: 13, // 14.0 km/h
    13: 13, // 14.5 km/h
    14: 14, // 15.0 km/h
    15: 14, // 15.5 km/h
    16: 15, // 16.0 km/h
    17: 15, // 16.5 km/h
    18: 16, // 17.0 km/h
  };

  // Level -> speed km/h (start 8.5 km/h, +0.5 each level)
  double _speedForLevel(int level) => 8.5 + (level - 1) * 0.5;

  // Her şutle için gereken süre (saniye)
  double _intervalForLevel(int level) {
    final speed = _speedForLevel(level); // km/h
    // 20m = 0.02 km, speed km/h -> saniye = (0.02 / speed) * 3600
    return (0.02 / speed) * 3600;
  }

  @override
  void initState() {
    super.initState();
    _loadAthletes();
    _beepPlayer.setSource(AssetSource('sounds/yoyobeepsound.mp3'));
  }

  @override
  void dispose() {
    _beepTimer?.cancel();
    _testTimer?.cancel();
    _beepPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    final list = await _db.getAllAthletes();
    setState(() => _allAthletes = list);
  }

  /* ==================== Test flow ==================== */
  void _startTest() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Lütfen sporcu seçin'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _currentLevel = 1;
      _currentShuttle = 0;
      _elapsedSeconds = 0;
      _levelStartTime = 0;
      _active = List.from(_selected);
      _warnings = {for (var a in _active) a.id: 0};
      _failed = {for (var a in _active) a.id: false};
      _athleteLevels = {for (var a in _active) a.id: 1};
      _athleteShuttles = {for (var a in _active) a.id: 0};
      _athleteDistances = {for (var a in _active) a.id: 0};
    });

    _startTimers();
  }

  void _startTimers() {
    _levelStartTime = _elapsedSeconds;
    _scheduleNextBeep();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _elapsedSeconds++);
        _checkLevelAdvance();
      }
    });
  }

  void _checkLevelAdvance() {
    // Her seviye 60 saniye sürer
    if (_elapsedSeconds - _levelStartTime >= 60) {
      _advanceLevel();
    }
  }

  void _advanceLevel() {
    setState(() {
      _currentLevel++;
      _currentShuttle = 0;
      _levelStartTime = _elapsedSeconds;
    });
    _scheduleNextBeep();
  }

  void _scheduleNextBeep() {
    final interval = _intervalForLevel(_currentLevel);
    _beepTimer = Timer(Duration(milliseconds: (interval * 1000).round()), () {
      if (!_isRunning || _isPaused) return;
      _playBeep();
      _advanceShuttle();
      _scheduleNextBeep();
    });
  }

  void _playBeep() {
    _beepPlayer.play(AssetSource('sounds/yoyobeepsound.mp3'));
  }

  void _advanceShuttle() {
    setState(() {
      _currentShuttle++;
      // Aktif sporcuların şutle sayısını güncelle
      for (final athlete in _active) {
        if (!_failed[athlete.id]!) {
          _athleteShuttles[athlete.id] = _athleteShuttles[athlete.id]! + 1;
          _athleteLevels[athlete.id] = _currentLevel;
          _athleteDistances[athlete.id] = _athleteDistances[athlete.id]! + 20; // Her şutle 20m
        }
      }
    });
  }

  void _failAthlete(AthleteModel athlete) {
    setState(() {
      _failed[athlete.id] = true;
      _active.remove(athlete);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${athlete.name} ${athlete.surname} testi bıraktı'),
        backgroundColor: AppTheme.warningColor,
      ),
    );

    // Tüm sporcular bıraktıysa testi bitir
    if (_active.isEmpty) {
      _stopTest();
    }
  }

  void _pauseTest() {
    setState(() => _isPaused = true);
    _beepTimer?.cancel();
    _testTimer?.cancel();
  }

  void _resumeTest() {
    setState(() => _isPaused = false);
    _startTimers();
  }

  void _stopTest() {
    _beepTimer?.cancel();
    _testTimer?.cancel();
    setState(() => _isRunning = false);
    _saveResults();
  }

  /* ==================== DB save ==================== */
  Future<void> _saveResults() async {
    final now = DateTime.now();
    final testId = '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(now)}_${now.millisecondsSinceEpoch}';
    final sessionId = '${testId}_0';

    for (final athlete in _selected) {
      final level = _athleteLevels[athlete.id] ?? 1;
      final shuttle = _athleteShuttles[athlete.id] ?? 0;
      final distance = _athleteDistances[athlete.id] ?? 0;
      final isFailed = _failed[athlete.id] ?? false;
      
      // Sonuç: Level.Shuttle formatında (örn: 12.3)
      final result = level + (shuttle / 10.0);
      
      final res = TestResultModel(
        id: '${testId}_${athlete.id}',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testName: '20m Shuttle Run Test',
        testId: testId,
        sessionId: sessionId,
        result: result,
        resultUnit: 'Level.Shuttle',
        testDate: now,
      );
      await _db.insertTestResult(res);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Sonuçlar kaydedildi'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    }
  }

  /* ==================== UI ==================== */
  String _formatTime(int sec) => '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

  String _getLevelInfo() {
    final speed = _speedForLevel(_currentLevel);
    final interval = _intervalForLevel(_currentLevel);
    return 'Seviye $_currentLevel • ${speed.toStringAsFixed(1)} km/h • ${interval.toStringAsFixed(1)}s/şutle';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('20m Shuttle Test'), backgroundColor: AppTheme.primaryColor, foregroundColor: AppTheme.whiteTextColor),
      body: Column(children: [
        _buildStatus(),
        if (!_isRunning) _buildSelection(),
        if (_isRunning) _buildActive(),
      ]),
    );
  }

  Widget _buildStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor,
      child: Column(children: [
        if (_isRunning) ...[
          Text('SEVİYE $_currentLevel • ŞUTLE $_currentShuttle', 
               style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_getLevelInfo(), 
               style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Aktif: ${_active.length}', 
               style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ] else ...[
          Text('HAZIR', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 8),
        Text(_formatTime(_elapsedSeconds), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (!_isRunning)
          ElevatedButton.icon(onPressed: _startTest, icon: const Icon(Icons.play_arrow), label: const Text('Başlat'))
        else
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!_isPaused)
              ElevatedButton.icon(onPressed: _pauseTest, icon: const Icon(Icons.pause), label: const Text('Duraklat'))
            else
              ElevatedButton.icon(onPressed: _resumeTest, icon: const Icon(Icons.play_arrow), label: const Text('Devam')),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _stopTest, icon: const Icon(Icons.stop), label: const Text('Bitir'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor)),
          ]),
      ]),
    );
  }

  Widget _buildSelection() {
    return Expanded(
      child: ListView.builder(
        itemCount: _allAthletes.length,
        itemBuilder: (_, i) {
          final a = _allAthletes[i];
          final sel = _selected.contains(a);
          return ListTile(
            leading: CircleAvatar(backgroundColor: sel ? AppTheme.primaryColor : AppTheme.secondaryColor, child: Text(a.name[0] + a.surname[0], style: const TextStyle(color: Colors.white))),
            title: Text('${a.name} ${a.surname}'),
            trailing: Checkbox(value: sel, onChanged: (_) => setState(() => sel ? _selected.remove(a) : _selected.add(a))),
          );
        },
      ),
    );
  }

  Widget _buildActive() {
    return Expanded(
      child: ListView.builder(
        itemCount: _active.length,
        itemBuilder: (_, i) {
          final a = _active[i];
          final level = _athleteLevels[a.id] ?? 1;
          final shuttle = _athleteShuttles[a.id] ?? 0;
          final distance = _athleteDistances[a.id] ?? 0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor, 
                child: Text('$level.$shuttle', style: const TextStyle(color: Colors.white, fontSize: 12))
              ),
              title: Text('${a.name} ${a.surname}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seviye: $level • Şutle: $shuttle'),
                  Text('Mesafe: ${distance}m'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.stop, color: AppTheme.errorColor),
                onPressed: () => _failAthlete(a),
                tooltip: 'Testi Bırak',
              ),
            ),
          );
        },
      ),
    );
  }
} 