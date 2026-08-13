# Release build proof: zero impact

Measured against `example/` on macOS (`flutter build macos --release`),
comparing `runApp(DesignQA.wrap(child: const ExampleApp()))` against
`runApp(const ExampleApp())` with the `design_qa` dependency otherwise
unchanged.

| Build | `App.framework` binary size |
| --- | --- |
| With `DesignQA.wrap` | 6,906,368 bytes |
| Without `DesignQA.wrap` | 6,906,368 bytes |

Byte-for-byte identical. The `.app` bundle size matched too (38.5MB both).

## Why, not just that

`DesignQA.wrap` is a `kDebugMode` branch (`lib/src/core/design_qa.dart`):

```dart
static Widget wrap({required Widget child, String configPath = 'design_qa.yaml'}) {
  if (kDebugMode) {
    return DesignQAOverlay(configPath: configPath, child: child);
  }
  return child;
}
```

`kDebugMode` is resolved to a compile-time constant `false` in release and
profile builds, so the Dart AOT compiler's tree shaker doesn't just skip
running the `if` branch at runtime - it proves the branch is unreachable
and removes the code entirely, including every class it referenced
(`DesignQAOverlay`, the property panel, every adapter, the AST patcher,
`package:analyzer` itself, ...). That's confirmed directly: searching the
release binary's strings for text that only exists in design_qa's overlay
code (the tracking-warning banner text, the "no live-editable properties"
message, the `design_qa_out` output path) finds nothing in either build,
while the app's own strings (`"This screen is clean"`) are present in
both.

```bash
strings App > /tmp/app_strings.txt
grep -i "widget location tracking is off" /tmp/app_strings.txt   # no match
grep -i "No live-editable properties for" /tmp/app_strings.txt   # no match
grep -i "design_qa_out" /tmp/app_strings.txt                     # no match
grep -i "This screen is clean" /tmp/app_strings.txt              # matches - app's own code is intact
```

## Reproducing this

```bash
cd example
flutter build macos --release
ls -la build/macos/Build/Products/Release/design_qa_example.app/Contents/Frameworks/App.framework/Versions/A/App
# then edit lib/main.dart to drop DesignQA.wrap, rebuild, diff the size
```
