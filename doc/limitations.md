# Limitations

Concrete cases where design_qa can't do something, and what to do about it.

## `--track-widget-creation` is a hard requirement

The overlay finds a tapped widget's source location via
`WidgetInspectorService` internals that Flutter marks `@protected` -
they're meant to be driven by DevTools over the VM service protocol, not
called in-process. There's no public, stable API for reading a widget's
creation location from application code, so design_qa calls them directly
anyway (see `lib/src/inspector/location_resolver.dart`). This is a
Flutter-internal dependency, not a published contract - a future Flutter
release could change its shape.

**What happens if it breaks or the flag is missing:** a startup self-test
(`TrackingProbe`) detects it and shows a persistent banner; inspect mode
stays disabled rather than half-working. **What to do:** relaunch with
`flutter run --track-widget-creation`; if the banner persists with the
flag on, the internal API shape has likely changed for your Flutter
version - file an issue with your Flutter version.

## Live preview only covers built-in layout/text widgets

Live editing works by mutating a `RenderObject` directly - it needs to
already know that widget type's render shape. Built in:
`Padding`, `Container`, `SizedBox`, `DecoratedBox`, `ColoredBox`, `Text`,
`Row`, `Column`.

**What happens with anything else** (your own custom widgets, third-party
package widgets, `AnimatedContainer`, `Card`, etc.): the widget still
selects and shows its ancestor breadcrumb, but the property panel says
there's nothing live-editable for it. **What to do:** select an ancestor
from the breadcrumb that *is* one of the built-ins above (e.g. select the
`Padding` your custom widget wraps, if it exposes one), or wrap the value
you want to tune in one of the supported widgets.

## Live preview can't turn on a property that isn't already set

Editing `padding` on a `Container` mutates the `RenderPadding` object
`Container.build()` creates *when `padding` is non-null* - if the
`Container` has no padding at all, that `RenderObject` doesn't exist, and
there's nothing to mutate live without a full rebuild (which is exactly
what live-mutation is avoiding). Same logic applies to `margin`, `color`
(needs `color:` or `decoration:` already set), `borderRadius` (needs a
`BoxDecoration` already set), and `Text`'s `style:`.

**What happens:** the property panel shows "not set in source" instead of
a control. **What to do:** add a starting value in source (e.g.
`padding: EdgeInsets.zero`), hot reload, then it's live-editable.

## `const` widgets

A `const Padding(...)` is a single shared instance reused everywhere it
appears - `--track-widget-creation` still records its constructor
location correctly, but if the *same* const instance is used in multiple
places in your tree, editing "the widget you tapped" live will visually
affect every place that const instance is rendered, since they're all the
same `Element`/render subtree conceptually reused... in practice this is
rare (Flutter mostly const-canonicalizes leaf widgets like `SizedBox`, not
whole subtrees with distinct positions), but if a live edit affects more
than the one instance you tapped, this is why. **What to do:** remove
`const` from that specific widget while iterating, add it back after
exporting.

## Third-party and generated widgets

Widgets from packages you don't own (Material/Cupertino components like
`Card`, `ListTile`, `ElevatedButton`; any pub package) generally aren't in
the adapter registry, for the same reason as "custom widgets" above -
they're `StatelessWidget`s composing several render objects in ways
design_qa doesn't know the shape of. Generated code (from `build_runner`,
`freezed`, etc.) has real `--track-widget-creation` locations, but editing
generated source is rarely what you want anyway - the source-of-truth is
the input file the generator ran on, and exporting a patch against
generated output will be overwritten on the next build. **What to do:**
select the nearest ancestor you do own via the breadcrumb.

## `TextStyle`/`BoxDecoration` that aren't literals in source

If `style:` is `Theme.of(context).textTheme.bodyMedium` (a lookup, not a
literal `TextStyle(...)`), live editing still works (it mutates the
*resolved* `RenderParagraph`), but **export** can't surgically insert one
field into an expression it can't see inside. It replaces the whole
`style:`/`decoration:` argument with a literal built from just the
field(s) you edited, and flags this clearly in the changelog. Any other
styling that expression was carrying (a theme's color, a font family) is
not preserved automatically - re-add it by hand after reviewing the diff.

## GoRouter route jumping

Routes from `GoRoute(path: ...)` are discovered and listed by
`dart run design_qa:init` (plain static analysis of your source), but
**tapping one to jump only works for plain `Navigator`/
`MaterialApp(routes:)` apps**. GoRouter manages its own navigation stack
independently of `Navigator.pushNamed`, and design_qa doesn't take a hard
dependency on `package:go_router` just to support jumping into it. If you
use GoRouter, treat the jumper as a reference list for now.

## Exporting from Android (emulator or physical device)

An Android emulator or physical device has no access to the host
machine's filesystem at all - reading your source files and writing
`design_qa_out/` can only happen on the machine that actually has your
project checked out. Exporting from Android goes through a VM-service
bridge instead: tap Export, then run
`dart run design_qa:export --vm-service-uri=<uri>` from your terminal
(the URI `flutter run` printed at startup). This is the same protocol
DevTools itself uses to reach an app on any device. macOS desktop doesn't
need this - `flutter run -d macos` has normal filesystem access and
exports directly when you tap the button (subject to your macOS App
Sandbox entitlements allowing file access if you've enabled sandboxing -
see the README's macOS notes).

## `mainAxisAlignment`/`crossAxisAlignment` UI, `borderRadius` UI

The property panel exposes a single uniform radius control (not four
independent corners) and dropdowns for the two `Flex` alignments - the
underlying value shapes (`BorderRadiusValue`, per-corner) and the
exporter both support asymmetric radii, but there's no UI for it yet. Set
an asymmetric radius in source and it round-trips correctly through
linting/export; you just can't drag it into that shape from the panel.
