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
        title: const Text(
          'Athletic Coach',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
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
              color: const Color(0xFFF3F4F6),
              iconColor: const Color(0xFF6366F1),
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
              color: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFF59E0B),
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
              color: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF3B82F6),
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
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 48, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color == const Color(0xFF6366F1) ? Colors.white : const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 