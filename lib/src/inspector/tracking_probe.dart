import 'package:flutter/widgets.dart';

import 'location_resolver.dart';

/// Answers one question at overlay startup: is `--track-widget-creation`
/// actually on for this run?
///
/// Rather than discovering that lazily the first time a designer taps a
/// widget (and guessing whether a null result means "flag is off" or "this
/// particular widget has no location"), we build one throwaway widget of
/// our own, immediately resolve its location, and use "did we get our own
/// location back" as ground truth. A miss here always means the flag is
/// off (or the resolver's internal-API dependency broke on this Flutter
/// version) - never a false negative about some other widget.
class TrackingProbe extends StatefulWidget {
  const TrackingProbe({super.key, required this.onResult});

  final ValueChanged<bool> onResult;

  @override
  State<TrackingProbe> createState() => _TrackingProbeState();
}

class _TrackingProbeState extends State<TrackingProbe> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final WidgetLocation? location = const LocationResolver().locate(context as Element);
      debugPrint('[design_qa] TrackingProbe result: location=$location');
      widget.onResult(location != null);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
