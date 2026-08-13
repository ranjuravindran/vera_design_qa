import 'dart:async';

import 'package:flutter/material.dart';

/// A `showDialog` stand-in for widgets inside [DesignQAOverlay]'s chrome.
///
/// Chrome sits under a bare [Overlay], not a [Navigator] - see
/// `_ChromeLayer`'s doc comment for why (a real `Navigator`'s `ModalRoute`
/// always inserts an invisible, unconditionally hit-testable
/// [ModalBarrier], which silently ate every tap meant for the app below
/// it). `showDialog`/`Navigator.of(context).pop()` don't work here as a
/// result; this inserts/removes an [OverlayEntry] directly instead.
Future<T?> showOverlayDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final OverlayState overlay = Overlay.of(context);
  final Completer<T?> completer = Completer<T?>();
  late final OverlayEntry entry;
  void dismiss([T? result]) {
    entry.remove();
    if (!completer.isCompleted) completer.complete(result);
  }

  entry = OverlayEntry(
    builder: (BuildContext context) => _OverlayDialogScope<T>(
      onDismiss: dismiss,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: dismiss,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

/// Lets a dialog built with [showOverlayDialog] call
/// `OverlayDialog.of<T>(context).pop(result)` instead of
/// `Navigator.of(context).pop(result)`.
class _OverlayDialogScope<T> extends InheritedWidget {
  const _OverlayDialogScope({required this.onDismiss, required super.child});

  final void Function([T? result]) onDismiss;

  @override
  bool updateShouldNotify(_OverlayDialogScope<T> oldWidget) => false;
}

class OverlayDialog<T> {
  const OverlayDialog._(this._scope);
  final _OverlayDialogScope<T> _scope;

  static OverlayDialog<T> of<T>(BuildContext context) {
    final _OverlayDialogScope<T>? scope =
        context.dependOnInheritedWidgetOfExactType<_OverlayDialogScope<T>>();
    assert(scope != null, 'OverlayDialog.of() called outside a showOverlayDialog builder');
    return OverlayDialog<T>._(scope!);
  }

  void pop([T? result]) => _scope.onDismiss(result);
}
