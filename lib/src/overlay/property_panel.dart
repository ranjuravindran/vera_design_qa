import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';
import '../core/edit_key.dart';
import '../inspector/location_resolver.dart';
import '../inspector/selection.dart';
import '../render_bridge/adapter.dart';
import '../render_bridge/edit_value_bridge.dart';
import '../tokens/token_lint.dart';
import 'controls/color_field.dart';
import 'controls/corner_radius_field.dart';
import 'controls/edge_insets_field.dart';
import 'controls/numeric_field.dart';
import 'design_qa_icons.dart';
import 'overlay_dialog.dart';
import 'property_sidebar.dart' show panelSeamBorder;

/// Content of the docked property sidebar (see [PropertySidebar]) for the
/// selected widget's editable properties as labeled controls, per the spec -
/// no Dart typing required from the designer. Fills whatever width its
/// parent gives it; sizing/docking/collapsing is the sidebar's job, not
/// this widget's.
///
/// Shows every editable ancestor in the tap's breadcrumb stacked as its own
/// section, Figma-style, rather than just the exact element that was
/// tapped - a tap usually lands on a leaf (an `Icon`, a `Text`) that has
/// nothing to edit, while the `Container`/`Padding`/`DecoratedBox` the
/// designer actually meant is one of its ancestors. Requiring a click
/// through tiny on-canvas breadcrumb chips to discover that meant most
/// taps dead-ended on "no live-editable properties" for no good reason.
class PropertyPanel extends StatelessWidget {
  const PropertyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final WidgetSelection selection = controller.selection!;
    final String headerType = friendlyWidgetTypeName(
        selection.location?.widgetType ??
            selection.element.widget.runtimeType.toString());

    final List<_SupportedAncestor> supported = <_SupportedAncestor>[];
    for (final BreadcrumbEntry entry in selection.breadcrumb) {
      final WidgetLocation? location = entry.location;
      if (location == null) continue;
      final String widgetType = location.widgetType;
      final PropertyAdapter? adapter =
          controller.adapterRegistry.forWidgetType(widgetType);
      final List<String> properties =
          controller.adapterRegistry.propertiesFor(widgetType).toList()..sort();
      if (adapter == null || properties.isEmpty) continue;
      supported.add(_SupportedAncestor(
        entry: entry,
        location: location,
        widgetType: widgetType,
        adapter: adapter,
        properties: properties,
      ));
    }

    return Container(
      decoration: const BoxDecoration(border: panelSeamBorder),
      child: Material(
        color: const Color(0xFF1E1E1E),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Header(widgetType: headerType),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: supported.isEmpty
                    ? _Unsupported(hasLocation: selection.location != null)
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: <Widget>[
                          for (int i = 0;
                              i < supported.length;
                              i++) ...<Widget>[
                            if (i > 0) ...<Widget>[
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Colors.white12),
                              const SizedBox(height: 14),
                            ],
                            _PropertySection(
                              key: ValueKey(supported[i].entry.element),
                              selection: selection,
                              ancestor: supported[i],
                              isNearest: i == 0,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportedAncestor {
  const _SupportedAncestor({
    required this.entry,
    required this.location,
    required this.widgetType,
    required this.adapter,
    required this.properties,
  });

  final BreadcrumbEntry entry;
  final WidgetLocation location;
  final String widgetType;
  final PropertyAdapter adapter;
  final List<String> properties;
}

class _PropertySection extends StatelessWidget {
  const _PropertySection(
      {super.key,
      required this.selection,
      required this.ancestor,
      required this.isNearest});

  final WidgetSelection selection;
  final _SupportedAncestor ancestor;
  final bool isNearest;

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: 'Highlight this layer on screen',
            waitDuration: const Duration(milliseconds: 500),
            child: InkWell(
              onTap: () =>
                  controller.select(selection.withAncestor(ancestor.entry)),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNearest
                            ? const Color(0xFF009DFF)
                            : Colors.white24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        friendlyWidgetTypeName(ancestor.widgetType),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isNearest ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final String property in ancestor.properties)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            // Keyed by (element, property): without this, Flutter can
            // reuse a _PropertyRowState across two rows that end up at the
            // same list position but back completely different properties
            // (e.g. a previous selection's crossAxisAlignment row and a new
            // selection's width row) - since _PropertyRowState only reads
            // the adapter value once, in initState, the stale value then
            // gets fed through the new property's (very different) switch
            // case, which is exactly the type-cast crash this fixes.
            child: _PropertyRow(
              key: ValueKey((ancestor.entry.element, property)),
              element: ancestor.entry.element,
              location: ancestor.location,
              widgetType: ancestor.widgetType,
              property: property,
              adapter: ancestor.adapter,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.widgetType});
  final String widgetType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Text(
        widgetType,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported({required this.hasLocation});
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        hasLocation
            ? "Nothing editable here yet - this layer and everything around it don't have "
                'adjustable spacing, fill, corner radius, or text style. Try tapping a nearby '
                'card, button, or text block instead.'
            : "This layer isn't part of your app's own screens (it's built into Flutter or a "
                "plugin), so there's nothing to edit. Try tapping something else on screen.",
        style:
            const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
      ),
    );
  }
}

class _PropertyRow extends StatefulWidget {
  const _PropertyRow({
    super.key,
    required this.element,
    required this.location,
    required this.widgetType,
    required this.property,
    required this.adapter,
  });

  final Element element;
  final WidgetLocation location;
  final String widgetType;
  final String property;
  final PropertyAdapter adapter;

  @override
  State<_PropertyRow> createState() => _PropertyRowState();
}

class _PropertyRowState extends State<_PropertyRow> {
  late Object? _value;
  late final Object? _initialValue;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.adapter.read(widget.element, widget.property);
    _initialValue = _value;
  }

  void _commit(Object? newValue) {
    setState(() {
      _value = newValue;
      _error = null;
    });
    try {
      widget.adapter.write(widget.element, widget.property, newValue);
    } on AdapterUnsupportedException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    final DesignQAController controller = DesignQAScope.of(context);
    final EditKey key = EditKey(
      file: widget.location.file,
      line: widget.location.line,
      column: widget.location.column,
      property: widget.property,
    );
    controller.session.apply(
      key: key,
      widgetType: widget.widgetType,
      value: toEditValue(newValue),
      originalValue: toEditValue(_initialValue ?? newValue),
    );
    controller.reapplyScheduler.trackElement(key, widget.element);
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final Object? value = _value;

    Widget control;
    LintSuggestion? lint;

    switch (widget.property) {
      case 'padding':
      case 'margin':
        if (value is EdgeInsets) {
          control = EdgeInsetsField(value: value, onChanged: _commit);
        } else {
          control = _placeholder();
        }
      case 'color':
        if (value is Color) {
          control = ColorField(
            label: 'Fill',
            value: value,
            onChanged: _commit,
          );
          lint = lintColor(
              value: value, config: controller.config, onApply: _commit);
        } else {
          control = _placeholder();
        }
      case 'borderRadius':
        final BorderRadius radius = value is BorderRadius ? value : BorderRadius.zero;
        control = CornerRadiusField(value: radius, onChanged: _commit);
        // Lints against the top-left corner only - the common case is all
        // four linked anyway, and this is advisory, not enforced, so it's
        // a reasonable simplification rather than a real limitation.
        lint = lintNumeric(
          category: TokenCategory.radius,
          value: radius.topLeft.x,
          config: controller.config,
          onApply: (double v) => _commit(BorderRadius.circular(v)),
        );
      case 'width':
      case 'height':
      case 'spacing':
        final double n = value is num ? value.toDouble() : 0;
        if (!n.isFinite) {
          // double.infinity is a real, common value here (e.g.
          // SizedBox(width: double.infinity) to fill available space) -
          // not something a numeric stepper can meaningfully edit.
          control = Text(
            '${_label(widget.property)}: fills available space',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          );
        } else {
          control = NumericField(
              label: _label(widget.property), value: n, onChanged: _commit);
          lint = lintNumeric(
            category: TokenCategory.spacing,
            value: n,
            config: controller.config,
            onApply: _commit,
          );
        }
      case 'fontSize':
        final double n = value is num ? value.toDouble() : 14;
        control = NumericField(label: 'Size', value: n, onChanged: _commit);
      case 'letterSpacing':
        final double n = value is num ? value.toDouble() : 0;
        control = NumericField(
            label: 'Letter spacing',
            value: n,
            step: 0.1,
            bigStep: 1,
            onChanged: _commit);
      case 'lineHeight':
        final double n = value is num ? value.toDouble() : 1.2;
        control = NumericField(
            label: 'Line height',
            value: n,
            step: 0.05,
            bigStep: 0.2,
            onChanged: _commit);
      case 'fontWeight':
        final double n = value is num ? value.toDouble() : 400;
        control = NumericField(
            label: 'Weight',
            value: n,
            step: 100,
            bigStep: 100,
            onChanged: _commit);
      // Figma's Auto Layout doesn't split "main" vs "cross" axis by name the
      // way Flutter's Row/Column do - "Distribution" (packed vs spaced-out)
      // and "Alignment" (align items along the other axis) are its closest
      // equivalents for the same two concepts.
      case 'mainAxisAlignment':
        control = _EnumDropdown<MainAxisAlignment>(
          label: 'Distribution',
          value: value is MainAxisAlignment ? value : MainAxisAlignment.start,
          values: MainAxisAlignment.values,
          onChanged: _commit,
        );
      case 'crossAxisAlignment':
        control = _EnumDropdown<CrossAxisAlignment>(
          label: 'Alignment',
          value: value is CrossAxisAlignment ? value : CrossAxisAlignment.center,
          values: CrossAxisAlignment.values,
          onChanged: _commit,
        );
      default:
        control = _placeholder();
    }

    final DesignQAIcon? icon = _iconFor(widget.property);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        icon == null
            ? control
            : Row(
                // Center rather than top-align: control is a single ~30px
                // field row for every property except EdgeInsetsField's
                // 2-row grid, and centering (instead of a fixed top offset
                // tuned for the single-row case) keeps the icon aligned to
                // whatever height the control actually turns out to be.
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    // 16px: close to the label text's own line height at
                    // fontSize 12, so the icon doesn't read as a mismatched
                    // size next to it.
                    child: DesignQAIconWidget(icon, size: 16, color: const Color(0x61FFFFFF)),
                  ),
                  Expanded(child: control),
                ],
              ),
        if (lint != null) LintChip(suggestion: lint),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 76),
            child: Text(_error!,
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
          ),
      ],
    );
  }

  Widget _placeholder() => Text(
        '${_label(widget.property)}: not set in source',
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      );

  // No icon for properties with no matching concept in the source icon set
  // (e.g. borderRadius - see the icon-pull agent's inventory) rather than
  // reaching for a misleading substitute.
  DesignQAIcon? _iconFor(String property) => switch (property) {
        'padding' || 'margin' || 'spacing' => DesignQAIcon.spacing,
        'color' => DesignQAIcon.color,
        'width' || 'height' => DesignQAIcon.size,
        'fontSize' ||
        'letterSpacing' ||
        'lineHeight' ||
        'fontWeight' =>
          DesignQAIcon.typography,
        'mainAxisAlignment' || 'crossAxisAlignment' => DesignQAIcon.alignCenter,
        _ => null,
      };

  String _label(String property) => switch (property) {
        'width' => 'Width',
        'height' => 'Height',
        'spacing' => 'Gap',
        _ => property,
      };
}

// 'spaceBetween' -> 'Space Between': enum names are camelCase Dart
// identifiers, not designer-facing copy.
String _humanizeEnumName(String camelCase) {
  final String spaced = camelCase.replaceAllMapped(
    RegExp('([a-z0-9])([A-Z])'),
    (Match m) => '${m[1]} ${m[2]}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    // Not a real DropdownButton: that widget pushes its popup menu via
    // `Navigator.of(context)` internally, and design_qa's chrome
    // deliberately has no Navigator (see overlay_dialog.dart) - it would
    // throw there and the menu would just never open. This reuses the same
    // Navigator-free overlay pattern as the color picker instead.
    final T? picked = await showOverlayDialog<T>(
      context: context,
      builder: (BuildContext context) => _EnumPickerDialog<T>(label: label, value: value, values: values),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
            width: 76,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          // Same resting fill, height, and corner radius as NumericField's
          // TextField and ColorField's swatch trigger, so the three control
          // types read as one family of fields rather than three different
          // ones stacked in the same panel.
          child: InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _humanizeEnumName(value.name),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, color: Colors.white38, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnumPickerDialog<T extends Enum> extends StatelessWidget {
  const _EnumPickerDialog({required this.label, required this.value, required this.values});

  final String label;
  final T value;
  final List<T> values;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            for (final T v in values)
              InkWell(
                onTap: () => OverlayDialog.of<T>(context).pop(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 18,
                        child: v == value
                            ? const Icon(Icons.check_rounded, color: Color(0xFF009DFF), size: 16)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _humanizeEnumName(v.name),
                        style: TextStyle(
                          color: v == value ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
