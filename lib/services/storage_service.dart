import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_state.dart';

class StorageService {
  static const _storageKey = 'planner_state_v1';

  Future<PlannerState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      return PlannerState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PlannerState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.toJson()),
    );
  }
}
