import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/edit_key.dart';
import '../core/edit_record.dart';
import '../core/edit_session.dart';
import 'adapter_registry.dart';
import 'edit_value_bridge.dart';

/// Keeps live edits alive across app-triggered rebuilds.
///
/// Setting a value on a `RenderObject` directly (what every [PropertyAdapter]
/// does) is durable only until the owning `Element` rebuilds and calls
/// `updateRenderObject` again with the value computed from the widget's
/// original constructor arguments - which silently overwrites our override.
/// That happens on `setState` elsewhere in the app, on hot reload, on
/// navigation, etc.
///
/// Rather than hooking rebuild internals (not exposed publicly), this
/// re-asserts every tracked edit once per frame *the app itself already
/// produced* - `addPostFrameCallback` doesn't fire on idle frames, so an
/// idle screen costs nothing, and a screen that IS rebuilding gets its
/// edits reapplied on the very next frame it draws. Worst case is a
/// one-frame flash of the un-edited value, which is an acceptable
/// trade-off for "no required app-code changes" (see the process writeup
/// this package was built from).
///
/// If the edited `Element`'s identity changes entirely - moved in a list,
/// swapped for a different widget, an ancestor's `Key` changed - reapply
/// silently stops until the designer re-selects that widget (which calls
/// [trackElement] again). See doc/limitations.md.
class ReapplyScheduler {
  ReapplyScheduler({required this.session, required this.registry});

  final EditSession session;
  final AdapterRegistry registry;

  final Map<EditKey, WeakReference<Element>> _tracked = <EditKey, WeakReference<Element>>{};
  bool _scheduled = false;

  /// Bind [key] to the concrete element currently backing it, e.g. right
  /// after a live edit is made, or when re-selecting a widget that already
  /// has edits recorded from an earlier hot reload.
  void trackElement(EditKey key, Element element) {
    _tracked[key] = WeakReference<Element>(element);
    _ensureScheduled();
  }

  void _ensureScheduled() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback(_reapplyAll);
  }

  void _reapplyAll(Duration _) {
    _scheduled = false;
    if (session.isEmpty) return;
    for (final MapEntry<EditKey, EditRecord> entry in session.edits.entries) {
      final Element? element = _tracked[entry.key]?.target;
      if (element == null || element.debugIsDefunct) continue;
      final adapter = registry.forWidgetType(entry.value.widgetType);
      if (adapter == null) continue;
      try {
        adapter.write(element, entry.key.property, fromEditValue(entry.value.value));
      } catch (_) {
        // Render structure under this element changed (e.g. hot reload
        // removed the decoration this edit depended on). Skip this frame;
        // try again on the next one once the tree has settled.
      }
    }
    _ensureScheduled();
  }
}
