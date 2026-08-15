import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';
import 'design_qa_icons.dart';
import 'property_panel.dart';
import 'reference_panel.dart';

/// A visible seam between the app's own content and design_qa's panel -
/// without it the two dark-ish surfaces can blend together with nothing
/// marking where one ends and the other begins, unlike Figma's own
/// canvas/panel divider. Shared with [PropertyPanel] so the seam lines up
/// consistently across every state (empty or populated).
const BoxBorder panelSeamBorder = Border(left: BorderSide(color: Colors.white12));

/// Docked right-hand sidebar for property editing, laid out as a real
/// sibling of the app (not floated on top of it) so it never overlaps the
/// app's own UI - the app's content simply gets less width while this is
/// open, the same way Figma's own right panel works. Always present (and
/// always at full width) while the overlay chrome is on - like Figma's own
/// Design panel, it doesn't collapse or need to be reopened; it just shows
/// an empty state when nothing is selected yet.
class PropertySidebar extends StatelessWidget {
  const PropertySidebar({super.key});

  static const double _dragHandleWidth = 6;

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    if (!controller.overlayVisible) return const SizedBox.shrink();

    // Pin an exact width regardless of incoming constraints: as a
    // non-Expanded Row sibling, `Overlay` (used below so nested controls
    // like ColorField's picker can find an Overlay ancestor) would
    // otherwise size itself to `constraints.biggest` - i.e. grab whatever
    // finite width Row hands it, not just its own panel width - and
    // swallow the Expanded app pane entirely.
    return SizedBox(
      width: controller.propertyPanelWidth + _dragHandleWidth,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(builder: (BuildContext context) => const _SidebarContent()),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent();

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails d) =>
                    controller.setPropertyPanelWidth(controller.propertyPanelWidth - d.delta.dx),
                child: const SizedBox(width: 6),
              ),
            ),
            SizedBox(
              width: controller.propertyPanelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (controller.referenceImagePath != null) const ReferencePanel(),
                  Expanded(
                    child: controller.selection == null ? const _EmptyState() : const PropertyPanel(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: panelSeamBorder),
      child: Material(
        color: const Color(0xFF1E1E1E),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Text(
                  'Properties',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DesignQAIconWidget(DesignQAIcon.touch,
                            size: 28, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Turn on Inspect and tap an element to edit its properties here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
