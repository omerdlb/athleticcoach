import 'package:flutter/material.dart';

class AppTheme {
  // Ana Renkler
  static const Color primaryColor = Color(0xFF4CAF50);        // Orta yeşil
  static const Color secondaryColor = Color(0xFF81C784);      // Açık yeşil
  static const Color accentColor = Color(0xFF2E7D32);         // Koyu yeşil
  
  // Gradyan Renkler
  static const Color gradientStart = Color(0xFFE8F5E9);       // Çok açık mint
  static const Color gradientEnd = Color(0xFFF1FAF0);         // Neredeyse beyaz yeşil
  static const Color drawerGradientStart = primaryColor;
  static const Color drawerGradientEnd = accentColor;
  
  // Arka Plan Renkleri
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);
  static const Color cardBackgroundWithOpacity = Color(0x95FFFFFF); // 95% opacity
  
  // Metin Renkleri
  static const Color primaryTextColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color lightTextColor = Color(0xFF9CA3AF);
  static const Color whiteTextColor = Color(0xFFFFFFFF);
  
  // Durum Renkleri
  static const Color successColor = primaryColor;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = secondaryColor;
  
  // Cinsiyet Renkleri
  static const Color maleColor = primaryColor;
  static const Color femaleColor = Color(0xFFEF6C9E);
  
  // Gölge Renkleri
  static const Color shadowColor = primaryColor;
  static const Color shadowColorWithOpacity = Color(0x1A4CAF50); // 10% opacity yeşil
  
  // Border Renkleri
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color focusedBorderColor = primaryColor;
  static const Color errorBorderColor = Color(0xFFEF4444);
  
  // App Bar Tema
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: primaryColor,
    elevation: 0,
    iconTheme: IconThemeData(color: whiteTextColor),
    titleTextStyle: TextStyle(
      color: whiteTextColor,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );
  
  // Card Tema
  static CardTheme get cardTheme => CardTheme(
    color: cardBackgroundWithOpacity,
    elevation: 4,
    shadowColor: shadowColorWithOpacity,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  // Elevated Button Tema
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: whiteTextColor,
      elevation: 4,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  
  // Text Button Tema
  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  
  // Input Decoration Tema
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    labelStyle: const TextStyle(color: primaryColor),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
  
  // Floating Action Button Tema
  static FloatingActionButtonThemeData get floatingActionButtonTheme => const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: whiteTextColor,
    elevation: 6,
  );
  
  // Drawer Tema
  static DrawerThemeData get drawerTheme => const DrawerThemeData(
    backgroundColor: Colors.transparent,
    width: 280,
  );
  
  // Icon Tema
  static IconThemeData get iconTheme => const IconThemeData(
    color: primaryColor,
    size: 24,
  );
  
  // Text Tema
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: primaryTextColor,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: primaryTextColor,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryTextColor,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: primaryTextColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: primaryTextColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: primaryTextColor,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primaryTextColor,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: primaryTextColor,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: secondaryTextColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: primaryTextColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: primaryTextColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: secondaryTextColor,
    ),
  );
  
  // Ana Tema
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    
    // Temalar
    appBarTheme: appBarTheme,
    cardTheme: cardTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    textButtonTheme: textButtonTheme,
    inputDecorationTheme: inputDecorationTheme,
    floatingActionButtonTheme: floatingActionButtonTheme,
    drawerTheme: drawerTheme,
    iconTheme: iconTheme,
    textTheme: textTheme,
    
    // Genel ayarlar
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    primarySwatch: MaterialColor(primaryColor.value, {
      50: primaryColor.withValues(alpha: 0.1),
      100: primaryColor.withValues(alpha: 0.2),
      200: primaryColor.withValues(alpha: 0.3),
      300: primaryColor.withValues(alpha: 0.4),
      400: primaryColor.withValues(alpha: 0.5),
      500: primaryColor,
      600: primaryColor.withValues(alpha: 0.7),
      700: primaryColor.withValues(alpha: 0.8),
      800: primaryColor.withValues(alpha: 0.9),
      900: primaryColor,
    }),
  );
  
  // Gradyan Dekorasyon
  static BoxDecoration get gradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gradientStart, gradientEnd],
    ),
  );
  
  // Drawer Gradyan Dekorasyon
  static BoxDecoration get drawerGradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [drawerGradientStart, drawerGradientEnd],
    ),
  );
  
  // Card Dekorasyon
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackgroundWithOpacity,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: shadowColorWithOpacity,
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );
  
  // Gölge Efekti
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadowColorWithOpacity,
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  // Responsive Font Boyutu
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return baseSize - 2;
    } else if (width > 600) {
      return baseSize + 2;
    }
    return baseSize;
  }
  
  // Responsive Padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return const EdgeInsets.all(12);
    } else if (width > 600) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(16);
  }
} 