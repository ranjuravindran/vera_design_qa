import 'package:flutter/material.dart';

import '../core/design_qa_scope.dart';
import '../inspector/selection.dart';

/// Draws the highlight box + dimensions around the current selection, and
/// the ancestor breadcrumb underneath it so a designer who tapped a child
/// widget can walk up to "the Padding or Container I actually meant to
/// hit" without re-tapping pixel-perfectly.
class InspectHighlight extends StatelessWidget {
  const InspectHighlight({super.key, required this.selection});

  final WidgetSelection selection;

  @override
  Widget build(BuildContext context) {
    final Rect? rect = selection.globalRect;
    if (rect == null) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: <Widget>[
            IgnorePointer(
              child: CustomPaint(
                painter: _HighlightPainter(rect),
                size: Size.infinite,
              ),
            ),
            Positioned(
              left: rect.left,
              top: (rect.top - 22).clamp(0, double.infinity),
              child: IgnorePointer(
                child: _Chip(
                  text: '${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}',
                  color: const Color(0xFF009DFF),
                ),
              ),
            ),
            Positioned(
              left: rect.left,
              top: rect.bottom + 4,
              right: 8,
              child: _Breadcrumb(selection: selection),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.rect);
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF009DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0x14009DFF));
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) => oldDelegate.rect != rect;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.selection});

  final WidgetSelection selection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final BreadcrumbEntry entry in selection.breadcrumb)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => DesignQAScope.of(context).select(selection.withAncestor(entry)),
                child: _Chip(
                  text: entry.label,
                  color: entry == selection.breadcrumb.first
                      ? const Color(0xFF009DFF)
                      : const Color(0xFF424242),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2)),
    );
  }
}
