import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athleticcoach/presentation/screens/athlete_add_screen.dart';
import 'package:athleticcoach/presentation/screens/test_library_screen.dart';
import 'package:athleticcoach/data/athlete_database.dart';

class OnboardingWidget {
  static Future<void> showOnboarding(BuildContext context) async {
    // Onboarding tamamlandı, isFirstLaunch'i false yap
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    
    await _showWelcomeDialog(context);
    await _showAddAthleteDialog(context);
    await _showTestLibraryDialog(context);
    await _showMainMenuDialog(context);
  }

  static Future<void> _showWelcomeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.waving_hand, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hoş Geldiniz!',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Athletic Coach uygulamasına hoş geldiniz! Size uygulamayı tanıtmak için birkaç adımda ilerleyelim.',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Başlayalım',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddAthleteDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sporcu Ekleyelim',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Öncelikle ilk sporcunuzu ekleyelim. Sporcu bilgilerini girerek başlayabilirsiniz.',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Sporcu Ekle',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Sporcu ekleme sayfasına git ve sonucu bekle
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AthleteAddScreen(),
      ),
    );
    
    if (result != null) {
      // Sporcu başarıyla eklendi, veritabanına kaydet
      await AthleteDatabase().insertAthlete(result);
    } else {
      // Sporcu eklenmedi, tekrar sporcu ekleme dialogunu göster
      await _showAddAthleteDialog(context);
    }
  }

  static Future<void> _showTestLibraryDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.library_books, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Testlere Göz Atalım',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Harika! Şimdi test kütüphanesine göz atalım. Mevcut testleri inceleyebilir ve yeni testler ekleyebilirsiniz.',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Test Kütüphanesi',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Test kütüphanesine git
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TestLibraryScreen(),
      ),
    );
  }

  static Future<void> _showMainMenuDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kurulum Tamamlandı!',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Mükemmel! Artık uygulamayı kullanmaya hazırsınız. Sol üstteki menü ikonuna tıklayarak tüm özelliklere erişebilirsiniz.',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Ana Menüye Dön',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 