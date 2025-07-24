import 'package:athleticcoach/data/predefined_data.dart';
import 'package:athleticcoach/data/models/test_definition_model.dart';
import 'package:athleticcoach/presentation/screens/test_session_select_athletes_screen.dart';
import 'package:flutter/material.dart';

class TestSessionSelectTestScreen extends StatelessWidget {
  const TestSessionSelectTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Seç'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: ListView.builder(
        itemCount: predefinedTests.length,
        itemBuilder: (context, index) {
          final test = predefinedTests[index];
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ListTile(
              leading: Icon(Icons.fitness_center, color: colorScheme.primary, size: 32),
              title: Text(test.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.category),
                  const SizedBox(height: 4),
                  Text(
                    test.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TestSessionSelectAthletesScreen(
                      selectedTest: test,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 