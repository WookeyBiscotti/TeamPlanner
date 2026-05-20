import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../models/planner_state.dart';
import 'import_parser.dart';
import 'save_json_file_stub.dart'
    if (dart.library.html) 'save_json_file_web.dart'
    if (dart.library.io) 'save_json_file_io.dart';

class ExportService {
  static const int formatVersion = 1;

  Map<String, dynamic> exportPayload(PlannerState state) => {
        'formatVersion': formatVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        ...state.toJson(),
      };

  String exportToJson(PlannerState state) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportPayload(state));
  }

  String defaultFilename() {
    final date = DateTime.now();
    return 'planner_export_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.json';
  }

  /// Saves project JSON to a file. Returns path or filename, or null if cancelled.
  Future<String?> saveProjectJson(PlannerState state) {
    return saveJsonFile(defaultFilename(), exportToJson(state));
  }

  Future<dynamic> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    return jsonDecode(utf8.decode(bytes));
  }

  Future<ImportParseResult?> pickAndParseImport() async {
    final decoded = await pickJsonFile();
    if (decoded == null) return null;
    return parseImportJson(decoded);
  }
}
