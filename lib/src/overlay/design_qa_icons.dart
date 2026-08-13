import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'design_qa_icon_data.dart';

/// Icons for design_qa's own chrome, pulled from a free Hugeicons set so
/// the tool reads as one visual language instead of mixing in generic
/// Material icons. Falls back silently to nothing where no source icon
/// matched a concept (see the icon-pull agent's inventory) - callers using
/// those slots keep a Material [Icon] instead.
///
/// The SVG markup is embedded as a string constant ([designQAIconData], in
/// design_qa_icon_data.dart) rather than loaded through Flutter's normal
/// asset system: design_qa is meant to be installed as a `dev_dependency`
/// (see the package's own install contract), and Flutter's asset bundler
/// does not include a package's own declared assets when it's only a
/// dev_dependency of the consuming app - confirmed by grepping a real
/// build's AssetManifest, where design_qa's icons/ folder was silently
/// absent even after a clean `pub get`. Embedding sidesteps that
/// limitation entirely instead of asking every consuming app to hand-wire
/// an assets entry for a tool they installed in one command.
enum DesignQAIcon {
  touch('touch'),
  route('route'),
  imageReference('image_reference'),
  export('export'),
  close('close'),
  color('color'),
  spacing('spacing'),
  size('size'),
  typography('typography'),
  alignLeft('align_left'),
  alignCenter('align_center'),
  alignRight('align_right'),
  opacity('opacity'),
  visibility('visibility'),
  visibilityOff('visibility_off'),
  lock('lock');

  const DesignQAIcon(this._dataKey);
  final String _dataKey;

  String get _svg => designQAIconData[_dataKey]!;
}

/// An [Icon]-equivalent backed by one of [DesignQAIcon]'s SVGs. Source
/// SVGs are drawn with a hardcoded stroke color, so this always force-tints
/// via [ColorFilter] rather than relying on `currentColor`.
class DesignQAIconWidget extends StatelessWidget {
  const DesignQAIconWidget(this.icon, {super.key, this.size = 18, this.color = const Color(0xFFFFFFFF)});

  final DesignQAIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      icon._svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
