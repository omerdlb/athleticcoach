import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:flutter/material.dart';

class TestProtocolScreen extends StatelessWidget {
  final TestDefinitionModel test;

  const TestProtocolScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(test.name),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5FE), Color(0xFFFDF6E3)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Center(
                  child: Icon(Icons.fitness_center, size: 60, color: colorScheme.primary),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'Açıklama',
                  color: colorScheme.primary,
                  child: Text(test.description, style: Theme.of(context).textTheme.bodyLarge),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'Ne İşe Yarar?',
                  color: colorScheme.secondary,
                  child: Text(test.purpose ?? 'Bilgi yok', style: Theme.of(context).textTheme.bodyLarge),
                ),
                const SizedBox(height: 18),
                _sectionCard(
                  context,
                  icon: Icons.rule,
                  title: 'Protokol',
                  color: colorScheme.tertiary,
                  child: Text(test.protocol, style: Theme.of(context).textTheme.bodyLarge),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.straighten, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text('Sonuç Birimi: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(test.resultUnit, style: TextStyle(color: colorScheme.tertiary)),
                  ],
                ),
                ..._buildReferenceTables(test, context, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required IconData icon, required String title, required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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

  List<Widget> _buildReferenceTables(TestDefinitionModel test, BuildContext context, ColorScheme colorScheme) {
    final List<Widget> tables = [];
    // Yo-Yo IR1
    if (test.id == 'yo-yo-ir1') {
      tables.add(const SizedBox(height: 28));
      tables.add(_sectionCard(
        context,
        icon: Icons.table_chart,
        title: 'Mekik/Seviye Tablosu',
        color: colorScheme.primary,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
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
        color: colorScheme.primary,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
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
        color: colorScheme.primary,
        child: DataTable(
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
        color: colorScheme.primary,
        child: DataTable(
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
} 