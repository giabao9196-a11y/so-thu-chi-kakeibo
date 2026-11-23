import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/calendar_screen.dart';
import 'screens/input_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;

  runApp(KakeiboMoneyNoteApp(initialDarkMode: isDark));
}

class KakeiboMoneyNoteApp extends StatefulWidget {
  final bool initialDarkMode;

  const KakeiboMoneyNoteApp({super.key, required this.initialDarkMode});

  @override
  State<KakeiboMoneyNoteApp> createState() => _KakeiboMoneyNoteAppState();
}

class _KakeiboMoneyNoteAppState extends State<KakeiboMoneyNoteApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() => _isDarkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Thu Chi Kakeibo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFE65100),
        scaffoldBackgroundColor: const Color(0xFFFBF9F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFBF9F5),
          foregroundColor: Color(0xFF2D2A26),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF8A50),
        scaffoldBackgroundColor: const Color(0xFF141413),
        cardColor: const Color(0xFF20201E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141413),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: MainShell(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MainShell({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _refreshCounter = 0;

  void _triggerRefresh() {
    setState(() {
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      InputScreen(
        key: ValueKey('input_$_refreshCounter'),
        onTransactionSaved: _triggerRefresh,
      ),
      CalendarScreen(refreshTrigger: _refreshCounter),
      ReportScreen(refreshTrigger: _refreshCounter),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onCategoriesUpdated: _triggerRefresh,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideDesktop = constraints.maxWidth >= 720;

        if (isWideDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  extended: constraints.maxWidth >= 980,
                  minExtendedWidth: 210,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        if (constraints.maxWidth >= 980) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Sổ Thu Chi\nKakeibo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.edit_outlined),
                      selectedIcon: Icon(Icons.edit),
                      label: Text('Nhập vào'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Lịch thu chi'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pie_chart_outline),
                      selectedIcon: Icon(Icons.pie_chart),
                      label: Text('Báo cáo'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Cài đặt & Khác'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: screens,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            height: 65,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.edit_outlined),
                selectedIcon: Icon(Icons.edit),
                label: 'Nhập vào',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Lịch',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Báo cáo',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Khác',
              ),
            ],
          ),
        );
      },
    );
  }
}
