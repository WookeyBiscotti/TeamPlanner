import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../models/planner_state.dart';
import 'download_file_stub.dart'
    if (dart.library.html) 'download_file_web.dart';

class ExportService {
  String exportToJson(PlannerState state) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(state.toJson());
  }

  void downloadJson(PlannerState state) {
    final date = DateTime.now();
    final filename =
        'planner_export_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.json';
    downloadFile(filename, exportToJson(state));
  }

  Future<PlannerState?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return PlannerState.fromJson(decoded);
  }
}
