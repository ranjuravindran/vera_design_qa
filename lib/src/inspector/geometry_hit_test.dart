import 'package:flutter/rendering.dart';

/// Finds every [RenderObject] under [position] within the subtree rooted at
/// [root], smallest bounding area first (so the most specific widget - e.g.
/// a `Padding` rather than the `Scaffold` behind it - is the default pick).
///
/// This mirrors the geometry-based traversal Flutter's own built-in
/// `WidgetInspector` uses for on-device widget selection (walk render
/// objects directly via [RenderObject.visitChildren] and
/// [RenderObject.applyPaintTransform], independent of the normal
/// hit-test-and-consume event pipeline) so that inspect mode can list every
/// candidate at a point - not just whichever one a real pointer event would
/// have been delivered to - which is what makes the ancestor breadcrumb
/// possible. Built entirely from public [RenderObject] API, unlike
/// [LocationResolver] which has to reach into inspector internals.
List<RenderObject> hitTestGeometry(Offset position, RenderObject root) {
  final List<RenderObject> hits = <RenderObject>[];
  _walk(hits, position, root, root.getTransformTo(null));
  hits.sort((RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)));
  return hits;
}

double _area(RenderObject object) {
  final Size size = object.semanticBounds.size;
  return size.width * size.height;
}

bool _walk(
  List<RenderObject> hits,
  Offset position,
  RenderObject object,
  Matrix4 transform,
) {
  final Matrix4? inverse = Matrix4.tryInvert(transform);
  if (inverse == null) return false;

  final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

  bool hit = false;
  object.visitChildren((RenderObject child) {
    final Matrix4 childTransform = transform.clone();
    object.applyPaintTransform(child, childTransform);
    if (_walk(hits, position, child, childTransform)) {
      hit = true;
    }
  });

  if (object.semanticBounds.contains(localPosition)) {
    hit = true;
  }
  if (hit) hits.add(object);
  return hit;
}
