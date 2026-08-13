/// A plain-Dart, Flutter-free representation of an edited value.
///
/// `EditRecord`/`EditSession` and the export pipeline (`SourcePatcher`,
/// `value_serializer.dart`) all need to run inside `bin/init.dart` and
/// `bin/export.dart` (`dart run design_qa:init` / `dart run
/// design_qa:export`) - plain Dart CLI processes with no Flutter engine
/// behind them. `dart:ui` (and therefore anything importing
/// `package:flutter/widgets.dart`, including `Color` and
/// `EdgeInsetsGeometry`) is only resolvable when the Flutter engine is
/// running the isolate, which a bare `dart run` process never is. So the
/// moment a live `Color` is recorded, it's converted to one of these
/// (see `render_bridge/edit_value_bridge.dart`, the only file allowed to
/// know about both sides) - everything downstream of that point, on both
/// the in-app and the host-CLI path, only ever touches [EditValue].
sealed class EditValue {
  const EditValue();

  Map<String, Object?> toJson();

  static EditValue fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'num' => NumValue(json['value']! as num),
      'color' => ColorValue(json['argb']! as int),
      'edgeInsets' => EdgeInsetsValue(
          left: json['left']! as num,
          top: json['top']! as num,
          right: json['right']! as num,
          bottom: json['bottom']! as num,
        ),
      'borderRadius' => BorderRadiusValue(
          topLeft: json['topLeft']! as num,
          topRight: json['topRight']! as num,
          bottomLeft: json['bottomLeft']! as num,
          bottomRight: json['bottomRight']! as num,
        ),
      'enum' => EnumValue(typeName: json['typeName']! as String, name: json['name']! as String),
      _ => throw FormatException('Unknown EditValue type: ${json['type']}'),
    };
  }
}

/// Covers every plain numeric property, including `fontWeight` - adapters
/// treat font weight as a 100-900 number (matching `FontWeight.value`), not
/// as a `FontWeight` object, so there's no separate value shape for it.
class NumValue extends EditValue {
  const NumValue(this.value);
  final num value;
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'num', 'value': value};
}

/// 0xAARRGGBB, matching `Color.toARGB32()`.
class ColorValue extends EditValue {
  const ColorValue(this.argb);
  final int argb;
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'color', 'argb': argb};
}

class EdgeInsetsValue extends EditValue {
  const EdgeInsetsValue({required this.left, required this.top, required this.right, required this.bottom});
  final num left, top, right, bottom;
  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'type': 'edgeInsets', 'left': left, 'top': top, 'right': right, 'bottom': bottom};
}

/// Uniform-corner case is the common one; `topLeft`/etc. cover the rest.
class BorderRadiusValue extends EditValue {
  const BorderRadiusValue({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
  final num topLeft, topRight, bottomLeft, bottomRight;
  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'borderRadius',
        'topLeft': topLeft,
        'topRight': topRight,
        'bottomLeft': bottomLeft,
        'bottomRight': bottomRight,
      };
}

/// `MainAxisAlignment.start`, `CrossAxisAlignment.center`, etc.
class EnumValue extends EditValue {
  const EnumValue({required this.typeName, required this.name});
  final String typeName;
  final String name;
  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'enum', 'typeName': typeName, 'name': name};
}
