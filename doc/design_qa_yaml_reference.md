# `design_qa.yaml` reference

Generated at your project root by `dart run design_qa:init`. Every key is
optional - a missing section just turns off the feature that reads it
(no tokens → no lint suggestions; no routes → an empty route jumper).
Re-running `init` only ever *appends* newly discovered routes; it never
touches tokens, comments, or anything else you've hand-edited.

```yaml
tokens:
  source: lib/tokens.dart      # informational only - where init found these
  colors:
    primary: '#FF2962FF'       # AARRGGBB or RRGGBB (alpha defaults to FF)
  spacing:
    md: 16                     # logical pixels
  radius:
    md: 8
  typography:
    body:
      fontSize: 14
      fontWeight: 400           # 100-900
      letterSpacing: 0.15
      lineHeight: 1.4

routes:
  - name: '/profile'
    mockArgs: { userId: 'demo-user-1' }   # passed as RouteSettings.arguments

reference:
  opacity: 0.5                 # 0-1, used by the 'opacity' blend mode
  blend: difference             # off | opacity | difference

lint:
  enabled: true
  tolerance: 0                 # allowed numeric drift before flagging, e.g. 0.5
```

## `tokens`

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `source` | string | none | Informational; not read back, just shown in the UI. |
| `colors` | map\<string, hex string\> | `{}` | Matched by exact value for "already a token" checks, by nearest RGBA distance for suggestions. |
| `spacing` | map\<string, number\> | `{}` | Used to lint `padding`/`margin`/`width`/`height`/`spacing`. |
| `radius` | map\<string, number\> | `{}` | Used to lint `borderRadius`. |
| `typography` | map\<string, object\> | `{}` | Not currently linted against (only spacing/radius/color are); reserved for a future release. |

`dart run design_qa:init` only auto-detects one pattern: a top-level class
made of `static const Color`/`double`/`int` fields (`class AppColors {
static const primary = Color(0xFF...); }`). `ThemeData`/`ColorScheme`-based
theming and external JSON/YAML token files aren't auto-detected - add them
under `tokens:` by hand; everything downstream (linting, the property
panel) works the same regardless of how the section got there.

## `routes`

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `name` | string | required | Must match a name your `Navigator` understands - see the GoRouter caveat below. |
| `mockArgs` | map | `{}` | Passed as `RouteSettings.arguments` via `Navigator.pushNamed(name, arguments: mockArgs)`. Your route builder reads it with `ModalRoute.of(context)!.settings.arguments`. |

Discovered automatically from `MaterialApp(routes: {...})` /
`CupertinoApp(routes: {...})` map literals, and from any `GoRoute(path:
...)` found in the project. **Jumping only works for plain
`Navigator`/`MaterialApp(routes:)` apps** - GoRouter routes are still
listed (useful as a reference / for future manual wiring) but tapping one
won't navigate a GoRouter app, since GoRouter manages navigation
independently of `Navigator.pushNamed` and design_qa doesn't take a hard
dependency on `package:go_router`. See doc/limitations.md.

## `reference`

| Key | Type | Default |
| --- | --- | --- |
| `opacity` | number, 0-1 | `0.5` |
| `blend` | `off` \| `opacity` \| `difference` | `off` |

Seeds the Figma reference overlay's starting state; `\` cycles through the
three blend modes at runtime regardless of what's here.

## `lint`

| Key | Type | Default |
| --- | --- | --- |
| `enabled` | bool | `true` |
| `tolerance` | number | `0` | Numeric drift allowed before a value is flagged, e.g. `0.5` to stop 15.5px from being flagged against a 16 token. |
