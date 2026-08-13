import 'package:flutter/widgets.dart';

import 'design_qa_controller.dart';

/// Exposes the running [DesignQAController] to the overlay's own widgets.
/// Not part of the public API - app code never touches this, only
/// design_qa's own pill/panel/overlay widgets read it via [of].
class DesignQAScope extends InheritedNotifier<DesignQAController> {
  const DesignQAScope({super.key, required DesignQAController controller, required super.child})
      : super(notifier: controller);

  static DesignQAController of(BuildContext context) {
    final DesignQAScope? scope = context.dependOnInheritedWidgetOfExactType<DesignQAScope>();
    assert(scope != null, 'DesignQAScope.of() called outside of DesignQA.wrap()');
    return scope!.notifier!;
  }
}
