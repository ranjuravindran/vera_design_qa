import 'package:flutter/widgets.dart';

import '../config/design_qa_config.dart';
import '../inspector/selection.dart';
import '../render_bridge/adapter_registry.dart';
import '../render_bridge/reapply_scheduler.dart';
import 'edit_session.dart';

enum DesignQAMode { idle, inspecting }

enum ReferenceBlendState { off, opacity, difference }

/// Everything the overlay's UI needs, in one place: current mode, selection,
/// pill position, reference-image state, and the loaded config. A single
/// [ChangeNotifier] rather than several so the overlay widget tree can
/// listen once via [DesignQAScope].
class DesignQAController extends ChangeNotifier {
  DesignQAController() {
    reapplyScheduler = ReapplyScheduler(session: EditSession.instance, registry: adapterRegistry);
  }

  final AdapterRegistry adapterRegistry = AdapterRegistry();
  final EditSession session = EditSession.instance;
  late final ReapplyScheduler reapplyScheduler;

  DesignQAMode _mode = DesignQAMode.idle;
  DesignQAMode get mode => _mode;
  set mode(DesignQAMode value) {
    if (_mode == value) return;
    _mode = value;
    if (value == DesignQAMode.idle) {
      _selection = null;
    }
    notifyListeners();
  }

  bool overlayVisible = true;
  void toggleOverlayVisible() {
    overlayVisible = !overlayVisible;
    notifyListeners();
  }

  /// Assumed on until [TrackingProbe] reports otherwise, so the overlay
  /// doesn't flash a warning banner during the first frame.
  bool trackingEnabled = true;
  void setTrackingEnabled(bool value) {
    if (trackingEnabled == value) return;
    trackingEnabled = value;
    notifyListeners();
  }

  /// Null until the designer drags the toolbar - [FloatingPill] then
  /// starts bottom-centered, like the toolbar in Figma and most other
  /// design tools, instead of pinned to a fixed pixel offset that doesn't
  /// adapt to the window/device size.
  Offset? pillPosition;
  void movePillTo(Offset value) {
    pillPosition = value;
    notifyListeners();
  }

  WidgetSelection? _selection;
  WidgetSelection? get selection => _selection;
  void select(WidgetSelection? value) {
    _selection = value;
    notifyListeners();
  }

  double propertyPanelWidth = 300;
  void setPropertyPanelWidth(double value) {
    propertyPanelWidth = value.clamp(240, 480);
    notifyListeners();
  }

  bool routeJumperOpen = false;
  void toggleRouteJumper() {
    routeJumperOpen = !routeJumperOpen;
    notifyListeners();
  }

  String? referenceImagePath;
  double referenceOpacity = 0.5;
  Offset referenceOffset = Offset.zero;
  double referenceScale = 1.0;
  ReferenceBlendState referenceBlend = ReferenceBlendState.off;

  void cycleReferenceBlend() {
    referenceBlend = switch (referenceBlend) {
      ReferenceBlendState.off => ReferenceBlendState.opacity,
      ReferenceBlendState.opacity => ReferenceBlendState.difference,
      ReferenceBlendState.difference => ReferenceBlendState.off,
    };
    notifyListeners();
  }

  void setReferenceImage(String? path) {
    referenceImagePath = path;
    notifyListeners();
  }

  void setReferenceOpacity(double v) {
    referenceOpacity = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setReferenceOffset(Offset v) {
    referenceOffset = v;
    notifyListeners();
  }

  void setReferenceScale(double v) {
    referenceScale = v.clamp(0.1, 5.0);
    notifyListeners();
  }

  DesignQAConfig config = DesignQAConfig.empty();
  void setConfig(DesignQAConfig value) {
    config = value;
    referenceOpacity = value.reference.opacity;
    notifyListeners();
  }
}
