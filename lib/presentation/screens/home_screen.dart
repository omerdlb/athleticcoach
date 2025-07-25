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
        title: Text(
          'Athletic Coach',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 22,
            color: const Color(0xFF1F2937),
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 4,
                color: const Color(0xFF1F2937).withOpacity(0.1),
              ),
            ],
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
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6366F1),
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sporcularınızı ve testlerinizi kolayca yönetin.',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B5563),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 400 ? 24 : 32),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
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
                      SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 20),
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
                      SizedBox(height: MediaQuery.of(context).size.width < 400 ? 16 : 20),
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
                      SizedBox(height: MediaQuery.of(context).size.width < 400 ? 80 : 100),
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
            bottom: MediaQuery.of(context).size.width < 400 ? 24 : 32,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.play_circle_fill, 
                size: MediaQuery.of(context).size.width < 400 ? 28 : 32
              ),
              label: Text(
                'Yeni Test Oturumu Başlat',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                  horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    // Ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive boyutlar hesapla
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;
    
    // Responsive padding ve boyutlar
    final cardPadding = isSmallScreen 
        ? const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16)
        : isMediumScreen 
            ? const EdgeInsets.symmetric(vertical: 24.0, horizontal: 18)
            : const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20);
    
    final iconSize = isSmallScreen ? 40.0 : isMediumScreen ? 48.0 : 54.0;
    final iconContainerPadding = isSmallScreen ? 12.0 : isMediumScreen ? 15.0 : 18.0;
    final titleFontSize = isSmallScreen ? 18.0 : isMediumScreen ? 20.0 : 22.0;
    final spacing = isSmallScreen ? 12.0 : isMediumScreen ? 15.0 : 18.0;
    
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: cardPadding,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(iconContainerPadding),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: iconSize, color: iconColor),
                ),
                SizedBox(height: spacing),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: titleFontSize,
                    color: color == const Color(0xFF6366F1)
                        ? Colors.white
                        : const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
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