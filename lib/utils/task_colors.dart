import 'package:flutter/material.dart';

const taskColorPalette = [
  Color(0xFF5C6BC0),
  Color(0xFF26A69A),
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFFAB47BC),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFF8D6E63),
];

Color colorForEmployee(String employeeId) {
  return taskColorPalette[employeeId.hashCode.abs() % taskColorPalette.length];
}
