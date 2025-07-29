import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:athleticcoach/presentation/screens/test_session_select_athletes_screen.dart';
import 'package:athleticcoach/presentation/screens/yo_yo_test_screen.dart';
import 'package:athleticcoach/presentation/screens/yo_yo_test_level2_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:athleticcoach/presentation/screens/beep_test_screen.dart';
import 'package:athleticcoach/presentation/screens/cooper_test_screen.dart';
import 'package:athleticcoach/presentation/screens/margaria_test_screen.dart';

class TestProtocolScreen extends StatelessWidget {
  final TestDefinitionModel test;

  const TestProtocolScreen({super.key, required this.test});

  void _startTestSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestSessionSelectAthletesScreen(
          selectedTest: test,
        ),
      ),
    );
  }

  void _startYoYoTest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const YoYoTestScreen(),
      ),
    );
  }

  void _startYoYoLevel2Test(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const YoYoTestLevel2Screen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(test.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.whiteTextColor,
        elevation: 2,
        actions: [
          if (test.id == 'yo-yo-ir1')
            IconButton(
              icon: Icon(
                Icons.sports_soccer,
                color: AppTheme.whiteTextColor,
                size: 28,
              ),
              tooltip: 'Yo-Yo Level 1 Test Başlat',
              onPressed: () => _startYoYoTest(context),
            ),
          if (test.id == 'yo-yo-ir2')
            IconButton(
              icon: Icon(
                Icons.sports_soccer,
                color: AppTheme.whiteTextColor,
                size: 28,
              ),
              tooltip: 'Yo-Yo Level 2 Test Başlat',
              onPressed: () => _startYoYoLevel2Test(context),
            ),
          if (test.id == 'beep-test')
            IconButton(
              icon: Icon(Icons.directions_run, color: AppTheme.whiteTextColor, size: 28),
              tooltip: '20m Shuttle Test Başlat',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BeepTestScreen())),
            ),
          if (test.id == 'cooper')
            IconButton(
              icon: Icon(Icons.timer, color: AppTheme.whiteTextColor, size: 28),
              tooltip: 'Cooper 12 Dakika Test Başlat',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CooperTestScreen())),
            ),
          if (test.id == 'margaria')
            IconButton(
              icon: Icon(Icons.fitness_center, color: AppTheme.whiteTextColor, size: 28),
              tooltip: 'Margaria Test Başlat',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MargariaTestScreen())),
            ),
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: AppTheme.whiteTextColor,
              size: 28,
            ),
            tooltip: 'Test Oturumu Başlat',
            onPressed: () => _startTestSession(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: AppTheme.gradientDecoration,
          ),
          Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: ListView(
          children: [
            Center(
              child: Icon(Icons.fitness_center, size: 60, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'Açıklama',
                  color: AppTheme.primaryColor,
                  child: Text(test.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryTextColor)),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'Ne İşe Yarar?',
                  color: AppTheme.secondaryColor,
                  child: Text(test.purpose ?? 'Bilgi yok', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryTextColor)),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.rule,
                  title: 'Protokol',
                  color: AppTheme.accentColor,
                  child: _buildProtocolWithLinks(context, test.protocol),
                ),
                const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.straighten, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text('Sonuç Birimi: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor)),
                Text(test.resultUnit, style: TextStyle(color: AppTheme.accentColor)),
              ],
            ),
                ..._buildReferenceTables(test, context),
          ],
        ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required IconData icon, required String title, required Color color, required Widget child}) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
      title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
          ),
    );
  }

  List<Widget> _buildReferenceTables(TestDefinitionModel test, BuildContext context) {
    final List<Widget> tables = [];
    // Yo-Yo IR1
    if (test.id == 'yo-yo-ir1') {
      tables.add(const SizedBox(height: 28));
      tables.add(_sectionCard(
        context,
        icon: Icons.table_chart,
        title: 'Mekik/Seviye Tablosu',
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            dataTextStyle: TextStyle(color: AppTheme.primaryTextColor),
            columns: const [
              DataColumn(label: Text('Seviye')), 
              DataColumn(label: Text('Toplam Mesafe (m)')),
              DataColumn(label: Text('VO2max (ml/kg/dk)')),
            ],
            rows: [
              for (var s = 5; s <= 20; s += 1)
                DataRow(cells: [
                  DataCell(Text(s.toString())),
                  DataCell(Text((s * 40).toString())),
                  DataCell(Text((s * 40 * 0.0084 + 36.4).toStringAsFixed(1))),
                ]),
            ],
          ),
        ),
      ));
    }
    // Cooper Testi
    if (test.id == 'cooper') {
      tables.add(const SizedBox(height: 28));
      tables.add(_sectionCard(
        context,
        icon: Icons.table_chart,
        title: 'Mesafe ve VO2max Tablosu',
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            dataTextStyle: TextStyle(color: AppTheme.primaryTextColor),
            columns: const [
              DataColumn(label: Text('Mesafe (m)')),
              DataColumn(label: Text('VO2max (ml/kg/dk)')),
            ],
            rows: [
              for (var m = 1800; m <= 3600; m += 200)
                DataRow(cells: [
                  DataCell(Text(m.toString())),
                  DataCell(Text(((m - 504.9) / 44.73).toStringAsFixed(1))),
                ]),
            ],
          ),
        ),
      ));
    }
    // Vertical Jump
    if (test.id == 'vertical-jump') {
      tables.add(const SizedBox(height: 28));
      tables.add(_sectionCard(
        context,
        icon: Icons.table_chart,
        title: 'Sıçrama Yüksekliği Değerlendirme',
        color: AppTheme.primaryColor,
        child: DataTable(
          headingTextStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(color: AppTheme.primaryTextColor),
          columns: const [
            DataColumn(label: Text('Yükseklik (cm)')),
            DataColumn(label: Text('Değerlendirme')),
          ],
          rows: const [
            DataRow(cells: [DataCell(Text('30 altı')), DataCell(Text('Zayıf'))]),
            DataRow(cells: [DataCell(Text('30-40')), DataCell(Text('Orta'))]),
            DataRow(cells: [DataCell(Text('41-50')), DataCell(Text('İyi'))]),
            DataRow(cells: [DataCell(Text('51-60')), DataCell(Text('Çok İyi'))]),
            DataRow(cells: [DataCell(Text('60+')), DataCell(Text('Elit'))]),
          ],
        ),
      ));
    }
    // RAST
    if (test.id == 'rast') {
      tables.add(const SizedBox(height: 28));
      tables.add(_sectionCard(
        context,
        icon: Icons.table_chart,
        title: 'Örnek Sprint ve Güç Tablosu',
        color: AppTheme.primaryColor,
        child: DataTable(
          headingTextStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(color: AppTheme.primaryTextColor),
          columns: const [
            DataColumn(label: Text('Sprint (sn)')),
            DataColumn(label: Text('Güç (Watt)')),
          ],
          rows: const [
            DataRow(cells: [DataCell(Text('5.0')), DataCell(Text('700'))]),
            DataRow(cells: [DataCell(Text('4.5')), DataCell(Text('850'))]),
            DataRow(cells: [DataCell(Text('4.0')), DataCell(Text('1000'))]),
            DataRow(cells: [DataCell(Text('3.5')), DataCell(Text('1200'))]),
          ],
        ),
      ));
    }
    // Diğer testler için de benzer şekilde eklenebilir...
    return tables;
  }

  Widget _buildProtocolWithLinks(BuildContext context, String protocol) {
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final spans = <TextSpan>[];
    final lines = protocol.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = urlRegex.firstMatch(line);
      if (match != null) {
        final url = match.group(0)!;
        final before = line.substring(0, match.start);
        final after = line.substring(match.end);
        if (before.isNotEmpty) {
          spans.add(TextSpan(text: before, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryTextColor)));
        }
        spans.add(
          TextSpan(
            text: url,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: (TapGestureRecognizer()
              ..onTap = () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }),
          ),
        );
        if (after.isNotEmpty) {
          spans.add(TextSpan(text: after, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryTextColor)));
        }
      } else {
        spans.add(TextSpan(text: line, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryTextColor)));
      }
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return SelectableText.rich(TextSpan(children: spans));
  }
} 