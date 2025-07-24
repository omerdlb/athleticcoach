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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Center(
              child: Icon(Icons.fitness_center, size: 60, color: colorScheme.primary),
            ),
            const SizedBox(height: 18),
            _buildSectionTitle(context, 'Açıklama', colorScheme.primary),
            const SizedBox(height: 8),
            Text(test.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            _buildSectionTitle(context, 'Protokol', colorScheme.secondary),
            const SizedBox(height: 8),
            Text(test.protocol, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.straighten, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Sonuç Birimi: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(test.resultUnit, style: TextStyle(color: colorScheme.tertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
    );
  }
} 