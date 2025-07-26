import 'package:flutter/material.dart';
import 'package:athleticcoach/presentation/screens/athlete_list_screen.dart';
import 'package:athleticcoach/presentation/screens/test_library_screen.dart';
import 'package:athleticcoach/presentation/screens/test_results_screen.dart';

class AppDrawerWidget {
  static Widget buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          ),
        ),
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Athletic Coach',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atletik Performans Yönetimi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'Ana Sayfa',
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      title: 'Sporcular',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AthleteListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.library_books,
                      title: 'Test Kütüphanesi',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TestLibraryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.analytics,
                      title: 'Test Sonuçları',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TestResultsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'Ayarlar',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Ayarlar sayfasına yönlendirme
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help,
                      title: 'Yardım',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Yardım sayfasına yönlendirme
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kullanıcı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'user@example.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hoverColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
} 