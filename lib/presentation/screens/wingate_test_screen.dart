import 'dart:async';
import 'package:flutter/material.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/data/athlete_database.dart';
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:intl/intl.dart';

/// Wingate Anaerobic Test
/// Kaynak: https://www.scienceforsport.com/wingate-anaerobic-test/
class WingateTestScreen extends StatefulWidget {
  const WingateTestScreen({super.key});

  @override
  State<WingateTestScreen> createState() => _WingateTestScreenState();
}

class _WingateTestScreenState extends State<WingateTestScreen> {
  final _db = AthleteDatabase();

  // Test state
  bool _isRunning = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  int _testDuration = 30; // 30 saniye test

  // Timers
  Timer? _testTimer;

  // Athletes
  List<AthleteModel> _allAthletes = [];
  List<AthleteModel> _selected = [];
  List<AthleteModel> _active = [];
  Map<String, List<double>> _powerReadings = {}; // athleteId -> power readings every 5s
  Map<String, bool> _completed = {}; // athleteId -> completed

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
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
      _elapsedSeconds = 0;
      _active = List.from(_selected);
      _powerReadings = {for (var a in _active) a.id: []};
      _completed = {for (var a in _active) a.id: false};
    });

    _startTimer();
  }

  void _startTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _elapsedSeconds++);
        
        // Her 5 saniyede bir güç okuması al
        if (_elapsedSeconds % 5 == 0 && _elapsedSeconds <= 30) {
          _recordPowerReadings();
        }
        
        // Test bitti
        if (_elapsedSeconds >= _testDuration) {
          _stopTest();
        }
      }
    });
  }

  void _recordPowerReadings() {
    // Bu fonksiyon gerçek uygulamada bisiklet ergometresinden veri alacak
    // Şimdilik simüle ediyoruz
    for (final athlete in _active) {
      if (!_completed[athlete.id]!) {
        final currentPower = _calculateSimulatedPower(athlete, _elapsedSeconds);
        _powerReadings[athlete.id]!.add(currentPower);
      }
    }
  }

  double _calculateSimulatedPower(AthleteModel athlete, int seconds) {
    // Simüle edilmiş güç hesaplama (gerçek uygulamada ergometre verisi kullanılır)
    final basePower = 800.0; // Baz güç
    final fatigue = seconds * 0.8; // Yorgunluk faktörü
    final random = (DateTime.now().millisecondsSinceEpoch % 100) - 50; // Rastgele varyasyon
    
    return (basePower - fatigue + random).clamp(200.0, 1000.0);
  }

  void _pauseTest() {
    setState(() => _isPaused = true);
    _testTimer?.cancel();
  }

  void _resumeTest() {
    setState(() => _isPaused = false);
    _startTimer();
  }

  void _stopTest() {
    _testTimer?.cancel();
    setState(() => _isRunning = false);
    _saveResults();
  }

  /* ==================== Power Calculations ==================== */
  double _calculatePeakPower(String athleteId) {
    final readings = _powerReadings[athleteId] ?? [];
    if (readings.isEmpty) return 0.0;
    return readings.reduce((a, b) => a > b ? a : b);
  }

  double _calculateAveragePower(String athleteId) {
    final readings = _powerReadings[athleteId] ?? [];
    if (readings.isEmpty) return 0.0;
    return readings.reduce((a, b) => a + b) / readings.length;
  }

  double _calculateFatigueIndex(String athleteId) {
    final readings = _powerReadings[athleteId] ?? [];
    if (readings.length < 2) return 0.0;
    
    final peakPower = readings.reduce((a, b) => a > b ? a : b);
    final lowestPower = readings.reduce((a, b) => a < b ? a : b);
    
    return ((peakPower - lowestPower) / peakPower) * 100;
  }

  double _calculateRelativePeakPower(String athleteId) {
    final peakPower = _calculatePeakPower(athleteId);
    final athlete = _active.firstWhere((a) => a.id == athleteId);
    final bodyWeight = athlete.weight;
    return bodyWeight > 0 ? peakPower / bodyWeight : 0.0;
  }

  /* ==================== DB save ==================== */
  Future<void> _saveResults() async {
    final now = DateTime.now();
    final testId = '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(now)}_${now.millisecondsSinceEpoch}';
    final sessionId = '${testId}_0';

    for (final athlete in _selected) {
      final peakPower = _calculatePeakPower(athlete.id);
      final averagePower = _calculateAveragePower(athlete.id);
      final fatigueIndex = _calculateFatigueIndex(athlete.id);
      final relativePeakPower = _calculateRelativePeakPower(athlete.id);
      final bodyWeight = athlete.weight ?? 0.0;
      
      final res = TestResultModel(
        id: '${testId}_${athlete.id}',
        athleteId: athlete.id,
        athleteName: athlete.name,
        athleteSurname: athlete.surname,
        testName: 'Wingate Anaerobic Test',
        testId: testId,
        sessionId: sessionId,
        result: peakPower,
        resultUnit: 'Watt',
        testDate: now,
        notes: 'PPO: ${peakPower.toStringAsFixed(1)}W, APO: ${averagePower.toStringAsFixed(1)}W, FI: ${fatigueIndex.toStringAsFixed(1)}%, RPP: ${relativePeakPower.toStringAsFixed(2)}W/kg, BW: ${bodyWeight.toStringAsFixed(1)}kg',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wingate Anaerobic Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
      ),
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
          Text('WINGATE TEST', 
               style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('30 Saniye Maksimum Güç Testi', 
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
            leading: CircleAvatar(
              backgroundColor: sel ? AppTheme.primaryColor : AppTheme.secondaryColor,
              child: Text(a.name[0] + a.surname[0], style: const TextStyle(color: Colors.white))
            ),
            title: Text('${a.name} ${a.surname}'),
            subtitle: Text('Vücut Ağırlığı: ${a.weight.toStringAsFixed(1)} kg'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel) ...[
                  const SizedBox(width: 8),
                ],
                Checkbox(
                  value: sel,
                  onChanged: (_) => setState(() => sel ? _selected.remove(a) : _selected.add(a)),
                ),
              ],
            ),
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
          final readings = _powerReadings[a.id] ?? [];
          final currentPower = readings.isNotEmpty ? readings.last : 0.0;
          final peakPower = _calculatePeakPower(a.id);
          final averagePower = _calculateAveragePower(a.id);
          final fatigueIndex = _calculateFatigueIndex(a.id);
          final bodyWeight = a.weight ?? 0.0;
          final relativePeakPower = bodyWeight > 0 ? peakPower / bodyWeight : 0.0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text('${a.name[0]}${a.surname[0]}', style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${a.name} ${a.surname}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Vücut Ağırlığı: ${bodyWeight.toStringAsFixed(1)} kg',
                              style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${currentPower.toStringAsFixed(0)}W',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Anlık Güç',
                            style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Peak Power', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                            Text('${peakPower.toStringAsFixed(1)}W', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${relativePeakPower.toStringAsFixed(2)}W/kg', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average Power', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                            Text('${averagePower.toStringAsFixed(1)}W', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fatigue Index', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                            Text('${fatigueIndex.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (readings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Güç Okumaları: ${readings.map((p) => p.toStringAsFixed(0)).join(', ')}W', 
                         style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 