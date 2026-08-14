import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/config_loader.dart';
import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';
import '../export/exporter.dart';
import '../inspector/element_utils.dart';
import '../inspector/geometry_hit_test.dart';
import '../inspector/location_resolver.dart';
import '../inspector/selection.dart';
import '../inspector/tracking_probe.dart';
import 'design_qa_theme.dart';
import 'device_preset.dart';
import 'floating_pill.dart';
import 'inspect_highlight.dart';
import 'property_sidebar.dart';
import 'reference_layer.dart';
import 'route_jumper.dart';
import 'tracking_banner.dart';

/// The whole overlay: the real app underneath, untouched, plus every piece
/// of design_qa chrome as siblings above it in a single [Stack]. Chrome is
/// a sibling rather than a descendant of the app on purpose - it must keep
/// working (and keep intercepting taps) no matter what the app's own
/// widget tree does, including when the app itself throws during build.
class DesignQAOverlay extends StatefulWidget {
  const DesignQAOverlay(
      {super.key, required this.child, required this.configPath});

  final Widget child;
  final String configPath;

  @override
  State<DesignQAOverlay> createState() => _DesignQAOverlayState();
}

class _DesignQAOverlayState extends State<DesignQAOverlay> {
  final GlobalKey _appKey = GlobalKey();
  late final DesignQAController _controller;
  late final FocusNode _focusNode;
  static const LocationResolver _resolver = LocationResolver();

  @override
  void initState() {
    super.initState();
    _controller = DesignQAController();
    _focusNode = FocusNode(skipTraversal: true);
    Exporter.registerVmServiceExtension();
    _loadConfig();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final String yamlText = await rootBundle.loadString(widget.configPath);
      _controller.setConfig(const ConfigLoader().loadFromString(yamlText));
    } catch (_) {
      // No config yet (not run through `dart run design_qa:init`, or the
      // file isn't registered as a Flutter asset) - overlay still runs,
      // just without routes/tokens until one is added. See README.
    }
  }

  void _handleTapUp(TapUpDetails details) {
    debugPrint('[design_qa] tap-capture fired at ${details.globalPosition}');
    _inspectAt(details.globalPosition);
  }

  void _inspectAt(Offset globalPosition) {
    debugPrint(
        '[design_qa] _inspectAt: trackingEnabled=${_controller.trackingEnabled}');
    if (!_controller.trackingEnabled) return;
    final RenderObject? root = _appKey.currentContext?.findRenderObject();
    debugPrint('[design_qa] _inspectAt: root=$root');
    if (root == null) return;
    final List<RenderObject> hits = hitTestGeometry(globalPosition, root);
    debugPrint('[design_qa] _inspectAt: hits=${hits.length}');
    for (final RenderObject candidate in hits) {
      final Element? element = elementOf(candidate);
      debugPrint(
          '[design_qa] _inspectAt: candidate=$candidate element=$element');
      if (element == null || element.debugIsDefunct) continue;
      final List<BreadcrumbEntry> breadcrumb =
          buildBreadcrumb(element, _resolver);
      debugPrint(
          '[design_qa] _inspectAt: breadcrumb=${breadcrumb.map((b) => b.label).toList()}, location=${breadcrumb.first.location}');
      final WidgetSelection selection = WidgetSelection(
        element: element,
        location: breadcrumb.first.location,
        breadcrumb: breadcrumb,
      );
      _controller.select(selection);
      debugPrint('[design_qa] _inspectAt: selection applied');
      return;
    }
    debugPrint('[design_qa] _inspectAt: no valid element found among hits');
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backslash) {
      _controller.cycleReferenceBlend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignQAScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          final bool inspecting = _controller.mode == DesignQAMode.inspecting;
          // Everything below is a sibling of `widget.child` in the same
          // Stack, not a descendant of its MaterialApp - so unlike normal
          // app widgets, this chrome has no Directionality/Material/
          // Localizations ancestor of its own and has to bring all three,
          // wrapping the whole subtree (not just the visible-chrome
          // branch) since Stack itself needs Directionality to resolve
          // its default alignment before it even reaches children.
          // Localizations specifically: without it, any Material widget
          // that actually reads MaterialLocalizations (TextField, the
          // property panel's numeric fields, the route jumper's search
          // box) throws and takes the *host app* down with it - this
          // isn't cosmetic, it's a hard crash. Using the built-in
          // Default*Localizations delegates (US English, no extra
          // dependency) rather than GlobalMaterialLocalizations, since
          // this chrome doesn't need real i18n, just to not crash.
          return Localizations(
            locale: const Locale('en', 'US'),
            delegates: const <LocalizationsDelegate<Object>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: TextDirection.ltr,
              // A real dark Theme for this chrome specifically (see
              // design_qa_theme.dart) - without it, every Material widget
              // in here (AlertDialog, Slider, DropdownButton...) falls back
              // to Flutter's default *light* theme, since this subtree
              // isn't a descendant of the app's own MaterialApp/Theme.
              child: Theme(
                data: buildDesignQAChromeTheme(),
                child: Material(
                  type: MaterialType.transparency,
                  child: KeyboardListener(
                    focusNode: _focusNode,
                    autofocus: true,
                    onKeyEvent: _handleKey,
                    child: Listener(
                      onPointerDown: (PointerDownEvent e) => debugPrint(
                          '[design_qa] OUTERMOST pointerDown at ${e.position} (does not consume)'),
                      // A Row, not a bare Stack: the property sidebar is a
                      // real sibling pane here, not chrome floated on top of
                      // the app (that's still what _ChromeLayer is, for the
                      // pill/route jumper/etc.) - so it takes its own slice
                      // of width instead of overlapping whatever the app has
                      // rendered on the right edge of the screen.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: _DeviceFrame(
                                    preset: _controller.devicePreset,
                                    child: IgnorePointer(
                                      key: _appKey,
                                      ignoring: inspecting,
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                                if (inspecting)
                                  Positioned.fill(
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (PointerDownEvent e) =>
                                          debugPrint(
                                              '[design_qa] RAW pointerDown at ${e.position}'),
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (TapDownDetails d) => debugPrint(
                                            '[design_qa] onTapDown at ${d.globalPosition}'),
                                        onTapUp: _handleTapUp,
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  ),
                                if (_controller.referenceBlend !=
                                        ReferenceBlendState.off &&
                                    _controller.referenceImagePath != null)
                                  const Positioned.fill(
                                      child: FigmaReferenceLayer()),
                                if (_controller.selection != null)
                                  Positioned.fill(
                                      child: InspectHighlight(
                                          selection: _controller.selection!)),
                                TrackingProbe(
                                    onResult: _controller.setTrackingEnabled),
                                if (_controller.overlayVisible)
                                  const Positioned.fill(child: _ChromeLayer()),
                              ],
                            ),
                          ),
                          const PropertySidebar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The pill, panel, route jumper, etc. need their own [Overlay] ancestor
/// for anything Overlay-based to work - like the outer [Directionality]/
/// [Material], design_qa's chrome doesn't sit inside the app's own
/// `MaterialApp`/`Navigator`, so nothing here is inherited from it.
///
/// This is deliberately a bare [Overlay], not a [Navigator]. A `Navigator`
/// running a [PageRouteBuilder] pulls in the whole `ModalRoute` machinery,
/// which *always* inserts a [ModalBarrier] entry - even fully transparent
/// (`barrierColor: null`) - and `ModalBarrier` is unconditionally
/// `HitTestBehavior.opaque`. That invisible barrier sat above the app in
/// this Stack and silently swallowed every tap before it ever reached the
/// inspect-mode tap layer below it. See `_showExportDialog` for how
/// design_qa's one dialog works without a real Navigator.
class _ChromeLayer extends StatelessWidget {
  const _ChromeLayer();

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => const _ChromeContent()),
      ],
    );
  }
}

class _ChromeContent extends StatelessWidget {
  const _ChromeContent();

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) => Stack(
        children: <Widget>[
          if (!controller.trackingEnabled) const TrackingWarningBanner(),
          if (controller.routeJumperOpen) const RouteJumperSheet(),
          const ReferenceControls(),
          const FloatingPill(),
        ],
      ),
    );
  }
}

/// Simulates a real phone screen inside the (desktop-sized) window a
/// designer is actually running the app in - like Chrome DevTools' device
/// toolbar - rather than trying to resize the OS window itself to match.
/// That was tried first and abandoned: getting a window to land on an
/// exact device size runs straight into real screen-space limits (verified
/// directly - macOS silently *clamps* a resize that doesn't fit, no error
/// at all) that a pure-Flutter frame doesn't have to deal with, and it
/// works identically for every platform this overlay runs on, not just
/// macOS. Only [child] (the app itself) is framed - the property sidebar
/// next to this Positioned.fill, and the pill/chrome layered on top of it,
/// both keep their own independent sizing regardless of the frame.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.preset, required this.child});

  final DevicePreset preset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!preset.isFramed) return child;

    final Size deviceSize = Size(preset.width!, preset.height!);
    return ColoredBox(
      // Letterbox background filling whatever space the frame doesn't -
      // only visible once a preset makes the frame smaller than the pane.
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            boxShadow: const <BoxShadow>[
              BoxShadow(blurRadius: 24, color: Colors.black54, offset: Offset(0, 10)),
            ],
          ),
          child: SizedBox.fromSize(
            size: deviceSize,
            // The app now measures and lays out as if this were its real
            // screen (MediaQuery.size), not just a visual crop - so
            // responsive breakpoints and text wrapping behave the way they
            // actually would on that device, not just look approximately
            // right.
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: deviceSize),
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
