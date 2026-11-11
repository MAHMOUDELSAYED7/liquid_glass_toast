# liquid_glass_toast

A customizable "liquid glass" toast for Flutter: frosted blur, a soft glow in
the accent color, an animated entrance, swipe-to-dismiss and one central place
to style every toast type.

Works on all Flutter platforms (Android, iOS, web, desktop).

## Usage

Wrap your app in `LiquidGlassToastScope` and describe every toast type once:

```dart
import 'package:liquid_glass_toast/liquid_glass_toast.dart';

void main() => runApp(
  LiquidGlassToastScope(
    theme: const LiquidGlassToastTheme(
      position: ToastPosition.bottom,
      textStyle: TextStyle(fontStyle: FontStyle.italic),
      success: ToastTypeTheme(
        color: Colors.green,
        duration: Duration(seconds: 2),
      ),
      error: ToastTypeTheme(
        icon: Icons.dangerous_rounded,
        duration: Duration(seconds: 5),
      ),
      warning: ToastTypeTheme(position: ToastPosition.top),
    ),
    child: const MaterialApp(home: MyHomePage()),
  ),
);
```

Then show a toast from anywhere with a `BuildContext`:

```dart
LiquidGlassToast.show(
  context,
  message: 'Saved successfully!',
  type: ToastType.success,
);
```

## Customization

Every `ToastTypeTheme` field is optional; anything left `null` keeps the
built-in default. Values passed directly to `show` win over the theme.

| `ToastTypeTheme` | Description |
|---|---|
| `color`, `icon` | Accent color and icon |
| `textColor` | Message color |
| `iconColor`, `iconSize` | The icon itself |
| `duration` | How long it stays (default: based on message length) |
| `position` | `ToastPosition.top` or `bottom` |

| `LiquidGlassToastTheme` | Description (logical pixels) | Default |
|---|---|---|
| `textStyle` | Base style of every message | white, 14, w600 |
| `position` | Default position | bottom |
| `topOffset` / `bottomOffset` | Distance from the screen edge | 16 / 110 |
| `horizontalMargin` | Gap from left/right edges | 16 |
| `padding` | Inner card padding | 16 x 14 |
| `borderRadius` | Card corner radius | 24 |
| `iconBadgeSize` | Icon circle diameter | 36 |
| `iconSpacing` | Gap between icon and message | 12 |

You can also call `LiquidGlassToast.configure(theme)` yourself instead of
using `LiquidGlassToastScope`.

## Example

See the [example](example) app.
