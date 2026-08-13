import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../overlay/design_qa_overlay.dart';

/// Entry point. `dart run design_qa:init` injects the one call this package
/// needs in application code: `DesignQA.wrap(child: <your root widget>)`
/// around whatever is passed to `runApp`.
class DesignQA {
  DesignQA._();

  /// Wraps [child] with the design QA overlay.
  ///
  /// In release and profile builds this returns [child] completely
  /// unmodified. The entire overlay widget tree lives behind this
  /// `kDebugMode` branch, which the Dart/AOT compiler resolves to a
  /// compile-time constant `false` outside debug builds - so the tree
  /// shaker removes every overlay class, not just skips building it. See
  /// doc/limitations.md and the build-size proof under example/.
  static Widget wrap({required Widget child, String configPath = 'design_qa.yaml'}) {
    if (kDebugMode) {
      return DesignQAOverlay(configPath: configPath, child: child);
    }
    return child;
  }
}
