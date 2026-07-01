import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/main.dart';
import 'package:studyflow/models/models.dart';
import 'package:studyflow/providers/providers.dart';
import 'package:studyflow/screens/ai_screen.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(AppSettings settings) : super() {
    state = settings;
  }
}

void main() {
  testWidgets('quick action labels use readable dark mode text color',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => _TestSettingsNotifier(
              AppSettings(aiApiKey: 'test-key', isDarkMode: true),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              primary: AppColors.primary,
              surface: AppColors.bgDark,
              onSurface: AppColors.darkOnSurface,
              onSurfaceVariant: AppColors.darkOnSurfaceVariant,
            ),
            scaffoldBackgroundColor: AppColors.bgDark,
            cardColor: AppColors.cardDark,
          ),
          home: const AIScreen(),
        ),
      ),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('学习方法建议'));

    expect(label.style?.color, AppColors.darkOnSurface);
  });
}
