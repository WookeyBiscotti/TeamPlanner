import 'package:shared_preferences/shared_preferences.dart';

/// UI preferences for the task editor (not part of project export).
class TaskEditorPreferences {
  static const _appearanceExpandedKey = 'task_appearance_section_expanded';

  static Future<bool?> loadAppearanceExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_appearanceExpandedKey)) return null;
    return prefs.getBool(_appearanceExpandedKey);
  }

  static Future<void> saveAppearanceExpanded(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appearanceExpandedKey, expanded);
  }
}
