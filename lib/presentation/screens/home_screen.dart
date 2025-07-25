import 'dart:math';
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
    final userName = 'Hoş geldin!'; // İleride dinamik yapılabilir
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Athletic Coach',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Arka plan degrade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFFDF6E3)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Athletic Coach',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sporcularınızı ve testlerinizi kolayca yönetin.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sabit buton
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label: const Text('Yeni Test Oturumu Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 22),
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 8,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title, required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Card(
        elevation: 6,
        shadowColor: iconColor.withOpacity(0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 54, color: iconColor),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: color == const Color(0xFF6366F1)
                            ? Colors.white
                            : const Color(0xFF1F2937),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 