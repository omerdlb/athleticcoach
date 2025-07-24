import 'package:athleticcoach/presentation/screens/test_library_screen.dart';
import 'package:athleticcoach/presentation/screens/test_session_select_test_screen.dart';
import 'package:athleticcoach/presentation/screens/athlete_list_screen.dart';
import 'package:athleticcoach/presentation/screens/test_results_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athletic Coach'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFeatureCard(
              context,
              title: 'Sporcular',
              icon: Icons.people,
              color: colorScheme.primaryContainer,
              iconColor: colorScheme.primary,
              onTap: () {
                debugPrint('Sporcular sayfasına geçiliyor...');
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AthleteListScreen(),
                    ),
                  );
                } catch (e, s) {
                  debugPrint('Sporcular sayfası hatası: $e\n$s');
                }
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              title: 'Test Kütüphanesi',
              icon: Icons.library_books,
              color: colorScheme.secondaryContainer,
              iconColor: colorScheme.secondary,
              onTap: () {
                debugPrint('Test Kütüphanesi sayfasına geçiliyor...');
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestLibraryScreen(),
                    ),
                  );
                } catch (e, s) {
                  debugPrint('Test Kütüphanesi hatası: $e\n$s');
                }
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              title: 'Test Sonuçları',
              icon: Icons.analytics,
              color: colorScheme.tertiaryContainer,
              iconColor: colorScheme.tertiary,
              onTap: () {
                debugPrint('Test Sonuçları sayfasına geçiliyor...');
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestResultsScreen(),
                    ),
                  );
                } catch (e, s) {
                  debugPrint('Test Sonuçları hatası: $e\n$s');
                }
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill, size: 28),
              label: const Text('Yeni Test Oturumu Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: () async {
                debugPrint('Yeni Test Oturumu başlatılıyor...');
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestSessionSelectTestScreen(),
                    ),
                  );
                } catch (e, s) {
                  debugPrint('Test oturumu başlatma hatası: $e\n$s');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title, required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 54, color: iconColor),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
} 