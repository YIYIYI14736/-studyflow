import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: MyApp()));
}

class AppColors {
  // · 淡雅青绿色 · 主色调                                  启用：青绿 ╱ 羊皮纸
  static const primaryGradient = [Color(0xFF6DB3A0), Color(0xFF8FC9B8)];
  static const accentGradient = [Color(0xFFA8D5BA), Color(0xFFC5E6CF)];
  static const successGradient = [Color(0xFF66BB6A), Color(0xFF81C784)];
  static const warmGradient = [Color(0xFF9BC2B0), Color(0xFFB8D8CB)];
  static const timerGradient = [Color(0xFF5FA895), Color(0xFF87C2B0)];
  static const energyGradient = [Color(0xFF4CAF72), Color(0xFF81C798)];

  // 单色
  static const primary = Color(0xFF6DB3A0);
  static const accent = Color(0xFF8FC9B8);
  static const success = Color(0xFF66BB6A);

  // 背景  — 极淡的青绿冷白
  static const bgLight = Color(0xFFF5F9F8);
  static const bgDark = Color(0xFF161D1A);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF222B27);

  // 科目色板 — 青绿相邻色系（湖水蓝 / 薄荷 / 苔绿 / 青瓷 / 蓝灰 …）
  static const subjectColors = [
    Color(0xFF6DB3A0), // 青瓷绿
    Color(0xFF5FA8D6), // 湖水蓝
    Color(0xFF8BC3A3), // 薄荷绿
    Color(0xFF95B8D1), // 浅蓝灰
    Color(0xFF7BB89E), // 碧绿
    Color(0xFFA3C9A8), // 苔绿
    Color(0xFF6DAFA7), // 青蓝
    Color(0xFF88B5A0), // 灰绿
    Color(0xFF74B9C9), // 浅青
    Color(0xFFB5C9B2), // 白苔
  ];

  static const darkOnSurface = Color(0xFFDFEAE3);
  static const darkOnSurfaceVariant = Color(0xFF8DA69B);

  // · 备选：淡雅羊皮纸黄 ·
  // 启用这组当主色：
  // static const primaryGradient = [Color(0xFFD4B896), Color(0xFFE8D5B0)];
  // static const accentGradient = [Color(0xFFC9A96E), Color(0xFFDFC18A)];
  // static const warmGradient = [Color(0xFFDFC79E), Color(0xFFECD9B8)];
  // static const timerGradient = [Color(0xFFC9A96E), Color(0xFFE0C392)];
  // static const primary = Color(0xFFD4B896);
  // static const accent = Color(0xFFE8D5B0);
  // static const bgLight = Color(0xFFFAF6EE);
  // static const bgDark = Color(0xFF1E1A14);
  // static const cardDark = Color(0xFF2A241C);
  // static const subjectColors = [
  //   Color(0xFFD4B896), Color(0xFFC9A96E), Color(0xFFE0C392),
  //   Color(0xFFBFA67E), Color(0xFFD9C9A8), Color(0xFFA88F6B),
  //   Color(0xFFC9B88A), Color(0xFFE5D4B5), Color(0xFF8B7355),
  //   Color(0xFFCDBF9A),
  // ];
  // static const darkOnSurface = Color(0xFFF0E6D6);
  // static const darkOnSurfaceVariant = Color(0xFFA89B83);
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
