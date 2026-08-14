/// Phone screen sizes, in logical points (the same unit `MediaQuery` itself
/// reports), for simulating a real device inside the overlay - see
/// [DesignQAOverlay]'s "device frame". `responsive` (no preset) fills
/// whatever space is available, matching the overlay's previous behavior.
///
/// Exact figures for very recent/unreleased hardware are best-effort
/// approximations, not verified spec sheets.
enum DevicePreset {
  responsive('Responsive', null, null),
  iphone17Pro('iPhone 17 Pro', 402, 874),
  galaxyS22Ultra('Galaxy S22 Ultra', 384, 854),
  pixel10('Pixel 10', 412, 915);

  const DevicePreset(this.label, this.width, this.height);

  final String label;
  final double? width;
  final double? height;

  bool get isFramed => width != null && height != null;
}
