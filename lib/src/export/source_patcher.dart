import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../analyzer_support/constructor_call.dart';
import '../core/edit_record.dart';
import '../core/edit_value.dart';
import 'value_serializer.dart';

class TextEdit {
  const TextEdit({required this.offset, required this.length, required this.replacement});
  final int offset;
  final int length;
  final String replacement;
}

class PatchOutcome {
  const PatchOutcome({required this.patchedSource, required this.notes, required this.editCount});
  final String patchedSource;
  final List<String> notes;
  final int editCount;
}

/// Turns recorded [EditRecord]s for one file back into source text.
///
/// Widget instances are located by matching `--track-widget-creation`'s
/// (line, column) against every [ConstructorCall] in a plain syntactic
/// parse (no resolved analysis needed - we only need argument lists and
/// literal shapes, not types). Editing an unrecognized widget type, or a
/// property whose value in source isn't a literal this package
/// understands, degrades to a clearly-noted best-effort patch rather than
/// silently dropping the edit or corrupting the file - see
/// doc/limitations.md.
///
/// Pure Dart, no Flutter import: this runs both in-app (macOS desktop) and
/// in the host-side `dart run design_qa:export` CLI process (Android/iOS),
/// which never has Flutter loaded - see edit_value.dart.
class SourcePatcher {
  const SourcePatcher();

  PatchOutcome patch(String originalSource, List<EditRecord> editsForThisFile) {
    final ParseStringResult parsed = parseString(content: originalSource, throwIfDiagnostics: false);
    final List<String> notes = <String>[];
    final List<TextEdit> textEdits = <TextEdit>[];

    final Map<String, List<EditRecord>> byInstance = <String, List<EditRecord>>{};
    for (final EditRecord e in editsForThisFile) {
      byInstance.putIfAbsent('${e.key.line}:${e.key.column}', () => <EditRecord>[]).add(e);
    }

    for (final List<EditRecord> group in byInstance.values) {
      final EditRecord first = group.first;
      final int expectedOffset =
          parsed.lineInfo.getOffsetOfLine(first.key.line - 1) + (first.key.column - 1);
      final ConstructorCall? call = _findCall(parsed.unit, expectedOffset, first.widgetType);
      if (call == null) {
        notes.add(
          'Could not locate a ${first.widgetType} at ${first.key.file}:${first.key.line}:'
          '${first.key.column} in source (file may have changed since inspecting) - skipped '
          '${group.length} edit(s).',
        );
        continue;
      }
      try {
        final _Resolution resolution = _resolveInstance(call, first.widgetType, group);
        textEdits.addAll(resolution.edits);
        notes.addAll(resolution.notes);
      } catch (err) {
        notes.add('Could not patch ${first.widgetType} at ${first.key.line}:${first.key.column} - $err');
      }
    }

    textEdits.sort((TextEdit a, TextEdit b) => b.offset.compareTo(a.offset));
    String source = originalSource;
    for (final TextEdit edit in textEdits) {
      source = source.replaceRange(edit.offset, edit.offset + edit.length, edit.replacement);
    }
    return PatchOutcome(patchedSource: source, notes: notes, editCount: textEdits.length);
  }

  ConstructorCall? _findCall(CompilationUnit unit, int expectedOffset, String widgetType) {
    ConstructorCall? best;
    int bestDelta = 1 << 30;
    unit.accept(
      ConstructorCallVisitor((ConstructorCall call) {
        if (call.typeName != widgetType) return;
        final int delta = (call.offset - expectedOffset).abs();
        // Small tolerance for a leading `const ` the location may or may not
        // include depending on Flutter version.
        if (delta <= 8 && delta < bestDelta) {
          bestDelta = delta;
          best = call;
        }
      }),
    );
    return best;
  }
}

class _Resolution {
  const _Resolution(this.edits, this.notes);
  final List<TextEdit> edits;
  final List<String> notes;
}

Expression? _findNamedArgValue(ArgumentList args, String name) {
  for (final Expression arg in args.arguments) {
    if (arg is NamedExpression && arg.name.label.name == name) return arg.expression;
  }
  return null;
}

TextEdit _setNamedArg(ArgumentList args, String name, String valueSource) {
  for (final Expression arg in args.arguments) {
    if (arg is NamedExpression && arg.name.label.name == name) {
      return TextEdit(offset: arg.expression.offset, length: arg.expression.length, replacement: valueSource);
    }
  }
  final int insertOffset = args.rightParenthesis.offset;
  final String prefix = args.arguments.isNotEmpty ? ', ' : '';
  return TextEdit(offset: insertOffset, length: 0, replacement: '$prefix$name: $valueSource');
}

_Resolution _resolveInstance(ConstructorCall call, String widgetType, List<EditRecord> edits) {
  final ArgumentList args = call.arguments;
  switch (widgetType) {
    case 'Padding':
      return _Resolution(
        <TextEdit>[_setNamedArg(args, 'padding', serializeEdgeInsets(edits.first.value as EdgeInsetsValue))],
        const <String>[],
      );
    case 'SizedBox':
      return _direct(args, edits, <String, String Function(EditValue)>{
        'width': (EditValue v) => serializeNum((v as NumValue).value),
        'height': (EditValue v) => serializeNum((v as NumValue).value),
      });
    case 'ColoredBox':
      return _Resolution(
        <TextEdit>[_setNamedArg(args, 'color', serializeColor(edits.first.value as ColorValue))],
        const <String>[],
      );
    case 'Row':
    case 'Column':
      return _direct(args, edits, <String, String Function(EditValue)>{
        'spacing': (EditValue v) => serializeNum((v as NumValue).value),
        'mainAxisAlignment': (EditValue v) => serializeEnum(v as EnumValue),
        'crossAxisAlignment': (EditValue v) => serializeEnum(v as EnumValue),
      });
    case 'DecoratedBox':
      return _resolveDecorationGroup(args, 'decoration', edits);
    case 'Container':
      return _resolveContainerGroup(args, edits);
    case 'Text':
      return _resolveTextGroup(args, edits);
  }
  return _Resolution(
    const <TextEdit>[],
    <String>['No source patcher for $widgetType - skipped ${edits.length} edit(s).'],
  );
}

_Resolution _direct(
  ArgumentList args,
  List<EditRecord> edits,
  Map<String, String Function(EditValue)> serializers,
) {
  final List<TextEdit> result = <TextEdit>[];
  for (final EditRecord e in edits) {
    final String Function(EditValue)? serialize = serializers[e.key.property];
    if (serialize == null) continue;
    result.add(_setNamedArg(args, e.key.property, serialize(e.value)));
  }
  return _Resolution(result, const <String>[]);
}

String _decoFieldSource(String property, EditValue value) => property == 'color'
    ? serializeColor(value as ColorValue)
    : serializeBorderRadius(value as BorderRadiusValue);

_Resolution _resolveDecorationGroup(ArgumentList hostArgs, String hostArgName, List<EditRecord> edits) {
  final Expression? existing = _findNamedArgValue(hostArgs, hostArgName);
  final ConstructorCall? existingCall = existing == null ? null : ConstructorCall.from(existing);
  if (existingCall != null && existingCall.typeName == 'BoxDecoration') {
    final ArgumentList nested = existingCall.arguments;
    final List<TextEdit> result = <TextEdit>[
      for (final EditRecord e in edits)
        _setNamedArg(nested, e.key.property, _decoFieldSource(e.key.property, e.value)),
    ];
    return _Resolution(result, const <String>[]);
  }

  final Map<String, String> fields = <String, String>{
    for (final EditRecord e in edits) e.key.property: _decoFieldSource(e.key.property, e.value),
  };
  final String literal =
      'BoxDecoration(${fields.entries.map((MapEntry<String, String> e) => '${e.key}: ${e.value}').join(', ')})';
  final List<String> notes = existing == null
      ? const <String>[]
      : <String>[
          '$hostArgName: was not a literal BoxDecoration(...) - replaced with a new one carrying '
              'just the edited field(s) (${fields.keys.join(', ')}); review the original expression.',
        ];
  return _Resolution(<TextEdit>[_setNamedArg(hostArgs, hostArgName, literal)], notes);
}

_Resolution _resolveContainerGroup(ArgumentList args, List<EditRecord> edits) {
  final List<EditRecord> direct = <EditRecord>[];
  final List<EditRecord> colorEdits = <EditRecord>[];
  final List<EditRecord> radiusEdits = <EditRecord>[];
  for (final EditRecord e in edits) {
    switch (e.key.property) {
      case 'padding':
      case 'margin':
      case 'width':
      case 'height':
        direct.add(e);
      case 'color':
        colorEdits.add(e);
      case 'borderRadius':
        radiusEdits.add(e);
    }
  }

  final List<TextEdit> result = <TextEdit>[
    for (final EditRecord e in direct)
      _setNamedArg(
        args,
        e.key.property,
        e.key.property == 'padding' || e.key.property == 'margin'
            ? serializeEdgeInsets(e.value as EdgeInsetsValue)
            : serializeNum((e.value as NumValue).value),
      ),
  ];
  final List<String> notes = <String>[];

  if (colorEdits.isNotEmpty || radiusEdits.isNotEmpty) {
    final bool usesColorArgDirectly =
        radiusEdits.isEmpty && colorEdits.isNotEmpty && _findNamedArgValue(args, 'color') != null;
    if (usesColorArgDirectly) {
      result.add(_setNamedArg(args, 'color', serializeColor(colorEdits.first.value as ColorValue)));
    } else {
      final _Resolution deco =
          _resolveDecorationGroup(args, 'decoration', <EditRecord>[...colorEdits, ...radiusEdits]);
      result.addAll(deco.edits);
      notes.addAll(deco.notes);
    }
  }
  return _Resolution(result, notes);
}

String _textFieldName(String property) => property == 'lineHeight' ? 'height' : property;

String _textFieldSource(EditRecord e) {
  final NumValue value = e.value as NumValue;
  return e.key.property == 'fontWeight' ? serializeFontWeight(value.value) : serializeNum(value.value);
}

_Resolution _resolveTextGroup(ArgumentList args, List<EditRecord> edits) {
  final Expression? existing = _findNamedArgValue(args, 'style');
  final ConstructorCall? existingCall = existing == null ? null : ConstructorCall.from(existing);
  if (existingCall != null && existingCall.typeName == 'TextStyle') {
    final ArgumentList nested = existingCall.arguments;
    final List<TextEdit> result = <TextEdit>[
      for (final EditRecord e in edits) _setNamedArg(nested, _textFieldName(e.key.property), _textFieldSource(e)),
    ];
    return _Resolution(result, const <String>[]);
  }

  final Map<String, String> fields = <String, String>{
    for (final EditRecord e in edits) _textFieldName(e.key.property): _textFieldSource(e),
  };
  final String literal =
      'TextStyle(${fields.entries.map((MapEntry<String, String> e) => '${e.key}: ${e.value}').join(', ')})';
  final List<String> notes = existing == null
      ? const <String>[]
      : <String>[
          'style: was not a literal TextStyle(...) - replaced with one containing only the edited '
              'field(s) (${fields.keys.join(', ')}); any other styling from the original expression '
              '(color, fontFamily, ...) was removed - re-apply it manually.',
        ];
  return _Resolution(<TextEdit>[_setNamedArg(args, 'style', literal)], notes);
}
