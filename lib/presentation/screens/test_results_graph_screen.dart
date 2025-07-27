import 'dart:math' as math;
import 'package:athleticcoach/data/models/athlete_model.dart';
import 'package:athleticcoach/data/models/test_result_model.dart';
import 'package:athleticcoach/services/gemini_service.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TestResultsGraphScreen extends StatefulWidget {
  final AthleteModel athlete;
  final List<TestResultModel> results;

  const TestResultsGraphScreen({super.key, required this.athlete, required this.results});

  @override
  State<TestResultsGraphScreen> createState() => _TestResultsGraphScreenState();
}

class _TestResultsGraphScreenState extends State<TestResultsGraphScreen> {
  late Map<String, List<TestResultModel>> _groupedResults;
  late String _selectedTest;
  bool _isLoadingAnalysis = false;
  String? _analysisText;

  @override
  void initState() {
    super.initState();
    _groupResults();
  }

  void _groupResults() {
    _groupedResults = {};
    for (final r in widget.results) {
      if (!_groupedResults.containsKey(r.testName)) {
        _groupedResults[r.testName] = [];
      }
      _groupedResults[r.testName]!.add(r);
    }
    // Varsayılan olarak ilk test seçili
    _selectedTest = _groupedResults.keys.first;
  }

  List<TestResultModel> get _selectedResults {
    final list = _groupedResults[_selectedTest] ?? [];
    list.sort((a, b) => a.testDate.compareTo(b.testDate));
    return list;
  }

  Future<void> _generateAnalysis() async {
    setState(() {
      _isLoadingAnalysis = true;
      _analysisText = null;
    });

    final text = await GeminiService.generateTrendAnalysis(
      athlete: widget.athlete,
      testName: _selectedTest,
      results: _selectedResults,
    );

    setState(() {
      _isLoadingAnalysis = false;
      _analysisText = text;
    });
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  Widget _buildFormattedAnalysis(String analysis) {
    final lines = analysis.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, height: 1.6)),
                Expanded(child: Text(trimmed.substring(1).trim(), style: const TextStyle(fontSize: 16, height: 1.6))),
              ],
            ),
          );
        } else if (RegExp(r'^[0-9]+\.').hasMatch(trimmed)) {
          final title = trimmed.replaceFirst(RegExp(r'^[0-9]+\.'), '').trim();
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(trimmed, style: const TextStyle(fontSize: 16, height: 1.6)),
          );
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final dates = <DateTime>[];
    double? minY;
    double? maxY;
    for (int i = 0; i < _selectedResults.length; i++) {
      spots.add(FlSpot(i.toDouble(), _selectedResults[i].result));
      dates.add(_selectedResults[i].testDate);
      final val = _selectedResults[i].result;
      minY = (minY == null) ? val : math.min(minY!, val);
      maxY = (maxY == null) ? val : math.max(maxY!, val);
    }

    // Y ekseni etiket aralığını hesapla (en fazla 6 etiket olacak şekilde)
    double yInterval = 1;
    if (minY != null && maxY != null) {
      final range = (maxY! - minY!).abs();
      if (range == 0) {
        yInterval = maxY! == 0 ? 1 : maxY! / 2;
      } else {
        final rawInterval = range / 5; // hedef ~5-6 etiket
        // 1, 2, 5 * 10^n kuralına yuvarla
        final double exponent = math.pow(10, math.max(0, (math.log(rawInterval) / math.ln10).floor())).toDouble();
        final fraction = rawInterval / exponent;
        if (fraction < 1.5) yInterval = 1.0 * exponent;
        else if (fraction < 3) yInterval = 2.0 * exponent;
        else if (fraction < 7) yInterval = 5.0 * exponent;
        else yInterval = 10.0 * exponent;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.athlete.name} ${widget.athlete.surname} – $_selectedTest'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test seçimi
            if (_groupedResults.length > 1)
              DropdownButton<String>(
                value: _selectedTest,
                items: _groupedResults.keys
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTest = val);
                  }
                },
              ),
            const SizedBox(height: 24),
            // Grafik
            Expanded(
              child: spots.isEmpty
                  ? Center(child: Text('Grafik için yeterli veri yok'))
                  : LineChart(
                      LineChartData(
                        minY: minY != null ? (minY! - yInterval) : null,
                        maxY: maxY != null ? (maxY! + yInterval) : null,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: yInterval,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final display = yInterval < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
                                return Text(display, style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                                return Text(DateFormat('dd/MM').format(dates[idx]), style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // AI Analiz butonu
            ElevatedButton.icon(
              onPressed: _isLoadingAnalysis ? null : _generateAnalysis,
              icon: Icon(Icons.auto_awesome, color: AppTheme.whiteTextColor),
              label: Text(_isLoadingAnalysis ? 'Analiz ediliyor...' : 'AI Analizi', style: TextStyle(color: AppTheme.whiteTextColor)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (_analysisText != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildFormattedAnalysis(_analysisText!),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 