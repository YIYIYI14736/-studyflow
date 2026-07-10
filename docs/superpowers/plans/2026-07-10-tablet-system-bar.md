# StudyFlow Tablet System Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app theme visually extend through the tablet navigation-bar inset without placing interactive controls under system navigation.

**Architecture:** Flutter remains edge-to-edge. A theme-aware `AnnotatedRegion<SystemUiOverlayStyle>` disables Android's navigation contrast scrim, while a theme-colored `ColoredBox` wraps the bottom `SafeArea` so only content—not background—is inset.

**Tech Stack:** Flutter Material, `SystemUiOverlayStyle`, Flutter widget tests, Android release build.

---

### Task 1: Add system-bar layout regressions

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add failing widget tests**

Add `material.dart` and `services.dart` imports, then add these tests:

```dart
testWidgets('system navigation bar is transparent without contrast scrim',
    (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));

  final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
    find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
  );
  expect(
    regions.any(
      (region) =>
          region.value.systemNavigationBarColor == Colors.transparent &&
          region.value.systemNavigationBarContrastEnforced == false,
    ),
    isTrue,
  );
});

testWidgets('bottom theme background surrounds the bottom safe area',
    (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));

  final navigationBar = find.byType(BottomNavigationBar);
  final surfaceColor = Theme.of(tester.element(navigationBar)).colorScheme.surface;
  final background = find.ancestor(
    of: navigationBar,
    matching: find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == surfaceColor,
    ),
  );

  expect(background, findsOneWidget);
  final safeArea = find.descendant(
    of: background,
    matching: find.byType(SafeArea),
  );
  expect(safeArea, findsOneWidget);
  expect(tester.widget<SafeArea>(safeArea).top, isFalse);
});
```

- [ ] **Step 2: Verify RED**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test test\widget_test.dart`

Expected: FAIL because no theme-aware `AnnotatedRegion` exists and the current `SafeArea` is outside the colored background.

### Task 2: Implement theme-colored edge-to-edge navigation

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1: Disable the system navigation contrast scrim**

Add `systemNavigationBarContrastEnforced: false` to the startup overlay style. Add a `MaterialApp.builder` that returns:

```dart
builder: (context, child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final iconBrightness = isDark ? Brightness.light : Brightness.dark;

  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarContrastEnforced: false,
    ),
    child: child!,
  );
},
```

- [ ] **Step 2: Paint the theme background behind the safe-area inset**

Replace the `SafeArea -> Container -> BottomNavigationBar` nesting with:

```dart
final bottomBarColor = Theme.of(context).colorScheme.surface;

bottomNavigationBar: ColoredBox(
  color: bottomBarColor,
  child: SafeArea(
    top: false,
    child: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      backgroundColor: bottomBarColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: '计划',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: '错题',
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 3: Verify GREEN**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test test\widget_test.dart`

Expected: all widget tests pass.

### Task 3: Verify and package

**Files:**
- Verify: all changed files

- [ ] **Step 1: Run all tests**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat test`

Expected: all tests pass with zero failures.

- [ ] **Step 2: Run static analysis**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat analyze`

Expected: `No issues found!`

- [ ] **Step 3: Build release APK**

Run: `cmd /c call F:\Phone\flutter\bin\flutter.bat build apk --release`

Expected: exit code 0 and `build/app/outputs/apk/release/StudyFlow.apk` is refreshed.

- [ ] **Step 4: Check the diff**

Run: `git diff --check`

Expected: no whitespace errors; unrelated working-tree edits remain untouched.
