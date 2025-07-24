import 'package:athleticcoach/data/predefined_data.dart';
import 'package:athleticcoach/presentation/screens/test_protocol_screen.dart';
import 'package:flutter/material.dart';

class TestLibraryScreen extends StatelessWidget {
  const TestLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Kütüphanesi'),
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
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        test.category,
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TestProtocolScreen(test: test),
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