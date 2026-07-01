import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/screens/home_screen.dart';
import 'package:studyflow/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('通知初始化失败: $e');
  }
  runApp(ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
    child: const MyApp(),
  ));
}

class AppColors {
  // 主色调 — 暖珊瑚橙
  static const primaryGradient = [Color(0xFFFF6B35), Color(0xFFFF8F65)];
  static const accentGradient = [Color(0xFFFFA726), Color(0xFFFFCC02)];
  static const successGradient = [Color(0xFF66BB6A), Color(0xFF81C784)];
  static const warmGradient = [Color(0xFFFF8A65), Color(0xFFFFAB91)];
  static const timerGradient = [Color(0xFFFF7043), Color(0xFFFFAB91)];
  static const energyGradient = [Color(0xFF4CAF50), Color(0xFF81C784)];

  // 单色
  static const primary = Color(0xFFFF6B35);
  static const accent = Color(0xFFFF8F65);
  static const success = Color(0xFF66BB6A);

  // 背景
  static const bgLight = Color(0xFFFFF8F5);
  static const bgDark = Color(0xFF1A1410);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF2A1F1A);

  // 科目色板 — 暖色系列
  static const subjectColors = [
    Color(0xFFFF6B35), // 珊瑚橙
    Color(0xFFFF8F65), // 深橙
    Color(0xFFFFA726), // 琥珀
    Color(0xFFFF7043), // 浅橙
    Color(0xFFFFCC02), // 金黄
    Color(0xFFEF6C00), // 深琥珀
    Color(0xFFFF5252), // 粉红
    Color(0xFFE65100), // 橙色
    Color(0xFFFFAB00), // 琥珀金
    Color(0xFFBF360C), // 焦橙
  ];

  static const darkOnSurface = Color(0xFFF5E6D8);
  static const darkOnSurfaceVariant = Color(0xFFB09988);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeData buildTheme(bool isDark) {
      final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
      final card = isDark ? AppColors.cardDark : AppColors.cardLight;
      final onSurface =
          isDark ? AppColors.darkOnSurface : const Color(0xFF1C1C1E);
      final onSurfaceVariant =
          isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF6B7280);

      return ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: AppColors.primary,
          secondary: const Color(0xFFFF8F65),
          tertiary: const Color(0xFFFFA726),
          surface: bg,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
        ),
        scaffoldBackgroundColor: bg,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: onSurfaceVariant),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: card,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFFB09988),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
