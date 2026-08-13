import 'package:flutter/widgets.dart';

import 'location_resolver.dart';
import 'selection.dart';

const int _maxBreadcrumbDepth = 12;

/// `RenderObject.debugCreator` is a plain public field wrapping a
/// [DebugCreator] (also public, from `package:flutter/widgets.dart`) - this
/// part of the framework is not internal, unlike the location lookup in
/// [LocationResolver].
Element? elementOf(RenderObject object) {
  final Object? creator = object.debugCreator;
  return creator is DebugCreator ? creator.element : null;
}

bool _looksLikeProjectFile(String file) =>
    !file.contains('/.pub-cache/') && !file.contains('/flutter/packages/');

/// Builds the ancestor chain for the breadcrumb, nearest-first, skipping
/// elements the resolver can't place in the user's own source (framework
/// internals, third-party package internals) so the breadcrumb stays useful
/// rather than full of noise like `NotificationListener` or `_InkFeature`.
List<BreadcrumbEntry> buildBreadcrumb(Element leaf, LocationResolver resolver) {
  final List<BreadcrumbEntry> entries = <BreadcrumbEntry>[];
  final WidgetLocation? leafLocation = resolver.locate(leaf);
  entries.add(BreadcrumbEntry(element: leaf, location: leafLocation));

  Element current = leaf;
  int guard = 0;
  while (entries.length < _maxBreadcrumbDepth && guard < 200) {
    guard++;
    Element? next;
    current.visitAncestorElements((Element ancestor) {
      next = ancestor;
      return false; // stop at the first (nearest) ancestor
    });
    if (next == null || next!.debugIsDefunct) break;
    final WidgetLocation? loc = resolver.locate(next!);
    if (loc != null && _looksLikeProjectFile(loc.file)) {
      entries.add(BreadcrumbEntry(element: next!, location: loc));
    }
    current = next!;
  }
  return entries;
}
