import 'package:flutter/material.dart';

import '../config/design_qa_config.dart';

enum TokenCategory { spacing, radius }

/// One inline, one-tap fix: "16 -> spacing.md (16)".
class LintSuggestion {
  const LintSuggestion({required this.label, required this.apply});
  final String label;
  final VoidCallback apply;
}

String _fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

LintSuggestion? lintNumeric({
  required TokenCategory category,
  required double value,
  required DesignQAConfig config,
  required ValueChanged<double> onApply,
}) {
  if (!config.lint.enabled) return null;
  final MapEntry<String, double>? nearest = category == TokenCategory.spacing
      ? config.tokens.nearestSpacing(value, tolerance: config.lint.tolerance)
      : config.tokens.nearestRadius(value, tolerance: config.lint.tolerance);
  if (nearest == null) return null;
  final String prefix = category == TokenCategory.spacing ? 'spacing' : 'radius';
  return LintSuggestion(
    label: '${_fmtNum(value)} → $prefix.${nearest.key} (${_fmtNum(nearest.value)})',
    apply: () => onApply(nearest.value),
  );
}

LintSuggestion? lintColor({
  required Color value,
  required DesignQAConfig config,
  required ValueChanged<Color> onApply,
}) {
  if (!config.lint.enabled) return null;
  final int argb = value.toARGB32();
  if (config.tokens.hasExactColor(argb)) return null;
  final MapEntry<String, int>? nearest = config.tokens.nearestColor(argb);
  if (nearest == null) return null;
  return LintSuggestion(
    label: '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()} → colors.${nearest.key}',
    apply: () => onApply(Color(nearest.value)),
  );
}

/// Shown inline under the property it applies to, not in a separate panel -
/// per the spec, token linting has to be right next to the value it's
/// flagging to be useful.
class LintChip extends StatelessWidget {
  const LintChip({super.key, required this.suggestion});
  final LintSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 76, bottom: 4),
      child: InkWell(
        onTap: suggestion.apply,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF614A00), borderRadius: BorderRadius.circular(4)),
          child: Text(
            suggestion.label,
            style: const TextStyle(color: Color(0xFFFFC947), fontSize: 10),
          ),
        ),
      ),
    );
  }
}
