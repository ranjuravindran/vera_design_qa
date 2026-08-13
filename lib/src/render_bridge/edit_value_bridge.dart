import 'package:flutter/widgets.dart';

import '../core/edit_value.dart';

/// The only file that knows about both a live Flutter value (what
/// [PropertyAdapter.read]/`write` traffic in) and its Flutter-free
/// [EditValue] form (what [EditSession] stores). Keeping the conversion in
/// one place means adding a new editable value shape only means adding one
/// case here, in [EditValue], and in value_serializer.dart.
EditValue toEditValue(Object? value) {
  return switch (value) {
    num n => NumValue(n),
    Color c => ColorValue(c.toARGB32()),
    EdgeInsets e => EdgeInsetsValue(left: e.left, top: e.top, right: e.right, bottom: e.bottom),
    BorderRadius b => BorderRadiusValue(
        topLeft: b.topLeft.x,
        topRight: b.topRight.x,
        bottomLeft: b.bottomLeft.x,
        bottomRight: b.bottomRight.x,
      ),
    Enum e => EnumValue(typeName: e.runtimeType.toString(), name: e.name),
    _ => throw ArgumentError('No EditValue mapping for ${value.runtimeType}'),
  };
}

/// Font weight is the one property both adapters and [EditValue] treat as a
/// plain 100-900 number rather than a `FontWeight` object - callers editing
/// `fontWeight` pass that number straight through as a [num].
Object fromEditValue(EditValue value) {
  return switch (value) {
    NumValue v => v.value.toDouble(),
    ColorValue v => Color(v.argb),
    EdgeInsetsValue v => EdgeInsets.fromLTRB(
        v.left.toDouble(),
        v.top.toDouble(),
        v.right.toDouble(),
        v.bottom.toDouble(),
      ),
    BorderRadiusValue v => BorderRadius.only(
        topLeft: Radius.circular(v.topLeft.toDouble()),
        topRight: Radius.circular(v.topRight.toDouble()),
        bottomLeft: Radius.circular(v.bottomLeft.toDouble()),
        bottomRight: Radius.circular(v.bottomRight.toDouble()),
      ),
    EnumValue v => _enumFromName(v.typeName, v.name),
  };
}

Object _enumFromName(String typeName, String name) {
  return switch (typeName) {
    'MainAxisAlignment' => MainAxisAlignment.values.byName(name),
    'CrossAxisAlignment' => CrossAxisAlignment.values.byName(name),
    _ => throw ArgumentError('No enum mapping for $typeName'),
  };
}
