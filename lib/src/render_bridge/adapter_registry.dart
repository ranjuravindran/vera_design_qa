import 'adapter.dart';
import 'adapters/container_adapter.dart';
import 'adapters/decorated_box_adapter.dart';
import 'adapters/flex_adapter.dart';
import 'adapters/padding_adapter.dart';
import 'adapters/sized_box_adapter.dart';
import 'adapters/text_adapter.dart';

/// Every built-in widget type design_qa knows how to live-edit. A widget
/// type with no entry here still gets selected and shown in the property
/// panel (its properties come from the source AST instead, read-only for
/// live preview) - see doc/limitations.md.
class AdapterRegistry {
  AdapterRegistry() {
    for (final PropertyAdapter adapter in <PropertyAdapter>[
      const PaddingAdapter(),
      const SizedBoxAdapter(),
      const ContainerAdapter(),
      const DecoratedBoxAdapter(),
      const ColoredBoxAdapter(),
      const TextAdapter(),
      const FlexAdapter(),
    ]) {
      for (final String type in adapter.widgetTypes) {
        _byType[type] = adapter;
      }
    }
  }

  final Map<String, PropertyAdapter> _byType = <String, PropertyAdapter>{};

  PropertyAdapter? forWidgetType(String widgetType) => _byType[widgetType];

  bool supports(String widgetType) => _byType.containsKey(widgetType);

  Set<String> propertiesFor(String widgetType) =>
      _byType[widgetType]?.supportedProperties ?? const <String>{};
}
