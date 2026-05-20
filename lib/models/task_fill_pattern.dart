import 'package:patterns_canvas/patterns_canvas.dart';

/// Decorative fill for timeline task bars ([PatternType] from patterns_canvas).
enum TaskFillPattern {
  dots(PatternType.dots, 'Точки'),
  diagonalLight(PatternType.diagonalLight, 'Диагональ (тонкая)'),
  diagonalThick(PatternType.diagonalThick, 'Диагональ (толстая)'),
  verticalLight(PatternType.verticalLight, 'Вертикаль (тонкая)'),
  verticalThick(PatternType.verticalThick, 'Вертикаль (толстая)'),
  horizontalLight(PatternType.horizontalLight, 'Горизонталь (тонкая)'),
  horizontalThick(PatternType.horizontalThick, 'Горизонталь (толстая)'),
  crosshatch(PatternType.crosshatch, 'Сетка'),
  checkers(PatternType.checkers, 'Клетка'),
  raindrops(PatternType.raindrops, 'Капли'),
  subtlepatch(PatternType.subtlepatch, 'Пятна'),
  texture(PatternType.texture, 'Текстура');

  const TaskFillPattern(this.patternType, this.label);

  final PatternType patternType;
  final String label;

  String get storageKey => patternType.name;

  static TaskFillPattern? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final p in TaskFillPattern.values) {
      if (p.storageKey == key) return p;
    }
    return null;
  }
}
