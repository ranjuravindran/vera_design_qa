import '../core/edit_value.dart';

/// Turns a recorded [EditValue] back into the literal Dart source that
/// would produce it. Deliberately Flutter-free (see edit_value.dart) so it
/// runs the same way in-app and in the host-side `dart run
/// design_qa:export` CLI process, which never has Flutter loaded.
String serializeNum(num value) {
  final double d = value.toDouble();
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

String serializeEdgeInsets(EdgeInsetsValue value) {
  final String l = serializeNum(value.left);
  final String t = serializeNum(value.top);
  final String r = serializeNum(value.right);
  final String b = serializeNum(value.bottom);
  if (l == t && t == r && r == b) return 'EdgeInsets.all($l)';
  if (l == r && t == b) return 'EdgeInsets.symmetric(horizontal: $l, vertical: $t)';
  return 'EdgeInsets.fromLTRB($l, $t, $r, $b)';
}

String serializeColor(ColorValue value) {
  final String hex = value.argb.toRadixString(16).padLeft(8, '0').toUpperCase();
  return 'Color(0x$hex)';
}

String serializeBorderRadius(BorderRadiusValue value) {
  final List<num> radii = <num>[value.topLeft, value.topRight, value.bottomLeft, value.bottomRight];
  if (radii.every((num r) => r == radii.first)) {
    return 'BorderRadius.circular(${serializeNum(radii.first)})';
  }
  return 'BorderRadius.only('
      'topLeft: Radius.circular(${serializeNum(value.topLeft)}), '
      'topRight: Radius.circular(${serializeNum(value.topRight)}), '
      'bottomLeft: Radius.circular(${serializeNum(value.bottomLeft)}), '
      'bottomRight: Radius.circular(${serializeNum(value.bottomRight)}))';
}

/// `weight` is the plain 100-900 number - see the note on [NumValue].
String serializeFontWeight(num weight) => 'FontWeight.w${weight.toInt()}';

String serializeEnum(EnumValue value) => '${value.typeName}.${value.name}';
