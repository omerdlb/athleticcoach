import 'package:flutter/material.dart';
import 'package:athleticcoach/presentation/screens/athlete_list_screen.dart';
import 'package:athleticcoach/presentation/screens/test_library_screen.dart';
import 'package:athleticcoach/presentation/screens/test_results_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';

class AppDrawerWidget {
  static Widget buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        decoration: AppTheme.drawerGradientDecoration,
        child: Column(
          children: [
            // Menu items
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 60, 8, 8),
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
                      icon: Icons.help,
                      title: 'Yardım',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showHelpDialog(context);
                      },
                    ),
                  ],
                ),
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

  static void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Uygulama Hakkında',
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Athletic Performance Coach',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versiyon: 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Uygulama Özellikleri:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('• 12 farklı fitness testi'),
              _buildFeatureItem('• Sporcu yönetimi'),
              _buildFeatureItem('• Test sonuçları takibi'),
              _buildFeatureItem('• AI destekli analiz'),
              _buildFeatureItem('• PDF rapor oluşturma'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Önemli Bilgi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tüm veriler telefonunuzda saklanmaktadır. Uygulama silinirse veya telefon sıfırlanırsa verileriniz kaybolabilir. Önemli verilerinizi düzenli olarak yedeklemenizi öneririz.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Destek:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sorularınız için geliştirici ile iletişime geçebilirsiniz.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryTextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tamam',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.primaryTextColor,
        ),
      ),
    );
  }
} 