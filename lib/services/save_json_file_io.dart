import 'dart:convert';

import 'package:file_picker/file_picker.dart';

Future<String?> saveJsonFile(String filename, String content) async {
  return FilePicker.platform.saveFile(
    dialogTitle: 'Экспорт проекта',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: utf8.encode(content),
  );
}
