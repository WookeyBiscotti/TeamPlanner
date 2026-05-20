import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/planner_notifier.dart';
import 'providers/theme_notifier.dart';
import 'screens/planner_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()..init()),
        ChangeNotifierProvider(create: (_) => PlannerNotifier()..init()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: 'Team Planner',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeNotifier.themeMode,
            home: const PlannerScreen(),
          );
        },
      ),
    );
  }
}
