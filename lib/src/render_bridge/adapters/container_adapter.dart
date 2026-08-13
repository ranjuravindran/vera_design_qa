import 'package:flutter/widgets.dart';

import '../adapter.dart';

/// `Container` is a `StatelessWidget` that composes plain `Padding` /
/// `ColoredBox` / `DecoratedBox` / `ConstrainedBox` widgets in `build()` -
/// it owns no render object itself. This walks that single-child chain once
/// per read/write to find the specific composed element each property
/// actually lives on, mirroring `Container.build()`'s own ordering
/// (see package:flutter/src/widgets/container.dart):
/// Align? -> Padding(content) -> ColoredBox(color) -> ClipPath? ->
/// DecoratedBox(decoration) -> DecoratedBox(foreground) ->
/// ConstrainedBox(constraints) -> Padding(margin) -> Transform?.
///
/// A property with no backing element (e.g. 'color' on a `Container` that
/// was never given a color or a decoration) can't be turned on live - see
/// doc/limitations.md - only values already present in source have a render
/// object to mutate.
class ContainerAdapter extends PropertyAdapter {
  const ContainerAdapter();

  static const Set<String> _wrapperTypes = <String>{
    'Align',
    'Padding',
    'ColoredBox',
    'ClipPath',
    'DecoratedBox',
    'ConstrainedBox',
    'Transform',
    'LimitedBox',
  };

  @override
  List<String> get widgetTypes => const <String>['Container'];

  @override
  Set<String> get supportedProperties =>
      const <String>{'padding', 'margin', 'color', 'borderRadius', 'width', 'height'};

  _ContainerParts _walk(Element containerElement) {
    final _ContainerParts parts = _ContainerParts();
    Element current = containerElement;
    bool seenConstrained = false;
    int guard = 0;
    while (guard < 20) {
      guard++;
      Element? child;
      current.visitChildren((Element e) => child ??= e);
      if (child == null) break;
      final String typeName = child!.widget.runtimeType.toString();
      if (!_wrapperTypes.contains(typeName)) break;
      switch (typeName) {
        case 'Padding':
          if (seenConstrained) {
            parts.marginPadding = child;
          } else {
            parts.contentPadding = child;
          }
        case 'ColoredBox':
          parts.colorBox = child;
        case 'DecoratedBox':
          final DecoratedBox widget = child!.widget as DecoratedBox;
          if (widget.position == DecorationPosition.background) parts.decoratedBox = child;
        case 'ConstrainedBox':
          parts.constrainedBox = child;
          seenConstrained = true;
      }
      current = child!;
    }
    return parts;
  }

  @override
  Object? read(Element element, String property) {
    final _ContainerParts parts = _walk(element);
    switch (property) {
      case 'padding':
        final RenderObject? ro = parts.contentPadding?.renderObject;
        return ro == null ? null : (ro as dynamic).padding as EdgeInsetsGeometry;
      case 'margin':
        final RenderObject? ro = parts.marginPadding?.renderObject;
        return ro == null ? null : (ro as dynamic).padding as EdgeInsetsGeometry;
      case 'color':
        if (parts.colorBox?.renderObject case final RenderObject ro?) {
          return (ro as dynamic).color as Color;
        }
        if (_boxDecorationOf(parts) case final BoxDecoration d?) return d.color;
        return null;
      case 'borderRadius':
        return _boxDecorationOf(parts)?.borderRadius;
      case 'width':
      case 'height':
        final RenderObject? ro = parts.constrainedBox?.renderObject;
        if (ro == null) return null;
        final BoxConstraints c = (ro as dynamic).additionalConstraints as BoxConstraints;
        if (property == 'width') return c.hasTightWidth ? c.minWidth : null;
        return c.hasTightHeight ? c.minHeight : null;
    }
    return null;
  }

  BoxDecoration? _boxDecorationOf(_ContainerParts parts) {
    final RenderObject? ro = parts.decoratedBox?.renderObject;
    if (ro == null) return null;
    final Decoration decoration = (ro as dynamic).decoration as Decoration;
    return decoration is BoxDecoration ? decoration : null;
  }

  @override
  void write(Element element, String property, Object? value) {
    final _ContainerParts parts = _walk(element);
    switch (property) {
      case 'padding':
        final RenderObject? ro = parts.contentPadding?.renderObject;
        if (ro == null || value is! EdgeInsetsGeometry) {
          throw AdapterUnsupportedException(
            'This Container has no padding to edit live - set padding: in source first.',
          );
        }
        (ro as dynamic).padding = value;
      case 'margin':
        final RenderObject? ro = parts.marginPadding?.renderObject;
        if (ro == null || value is! EdgeInsetsGeometry) {
          throw AdapterUnsupportedException(
            'This Container has no margin to edit live - set margin: in source first.',
          );
        }
        (ro as dynamic).padding = value;
      case 'color':
        if (value is! Color) throw AdapterUnsupportedException('Expected a Color.');
        if (parts.colorBox?.renderObject case final RenderObject ro?) {
          (ro as dynamic).color = value;
          return;
        }
        final RenderObject? decoRo = parts.decoratedBox?.renderObject;
        final BoxDecoration? decoration = _boxDecorationOf(parts);
        if (decoRo == null || decoration == null) {
          throw AdapterUnsupportedException(
            'This Container has no color or decoration to edit live - set one in source first.',
          );
        }
        (decoRo as dynamic).decoration = decoration.copyWith(color: value);
      case 'borderRadius':
        final RenderObject? decoRo = parts.decoratedBox?.renderObject;
        final BoxDecoration? decoration = _boxDecorationOf(parts);
        if (decoRo == null || decoration == null || value is! BorderRadiusGeometry) {
          throw AdapterUnsupportedException(
            'This Container has no BoxDecoration to edit live - set decoration: BoxDecoration(...) in source first.',
          );
        }
        (decoRo as dynamic).decoration = decoration.copyWith(borderRadius: value);
      case 'width':
      case 'height':
        final RenderObject? ro = parts.constrainedBox?.renderObject;
        if (ro == null || value is! num) {
          throw AdapterUnsupportedException(
            'This Container has no fixed size to edit live - set width/height in source first.',
          );
        }
        final BoxConstraints current = (ro as dynamic).additionalConstraints as BoxConstraints;
        final double? width =
            property == 'width' ? value.toDouble() : (current.hasTightWidth ? current.minWidth : null);
        final double? height = property == 'height'
            ? value.toDouble()
            : (current.hasTightHeight ? current.minHeight : null);
        (ro as dynamic).additionalConstraints = BoxConstraints.tightFor(width: width, height: height);
    }
  }
}

class _ContainerParts {
  Element? contentPadding;
  Element? marginPadding;
  Element? colorBox;
  Element? decoratedBox;
  Element? constrainedBox;
}
