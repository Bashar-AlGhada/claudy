# Design System (Material 3)

## Design Tokens

Spacing
- `Tokens.space2/4/8/12/16/24/32`

Radii
- `Tokens.cornerRadius`

Motion
- `Tokens.motionFast` (150ms)
- `Tokens.motionMedium` (240ms)
- `Tokens.motionSlow` (300ms)
- `Tokens.easeOut`, `Tokens.easeInOut`

Color
- Theme uses Material 3 `ColorScheme` derived from preset seed colors.
- Surfaces and overlays use `surface`, `surfaceVariant`, and alpha overlays to maintain contrast.

## Reusable Components

Core UI
- `AppCard`: consistent shape and interaction surface for tappable containers.
- `AppEmptyState`, `AppErrorState`: standardized empty/error states with optional actions.
- `AppSkeletonBox`, `AppSkeletonList`: lightweight skeleton placeholders without extra dependencies.

Weather UI
- `WeatherBackground`: condition-driven gradient backgrounds with optional particle effects.

## Usage Guidelines

Interactive elements
- Prefer `InkWell`/Material surfaces for ripple + keyboard/focus behavior.
- Keep interaction timings between 150–300ms using `Tokens.motion*`.

Loading states
- Prefer skeletons for page-level loads and show cached-to-fresh transitions without jarring layout shifts.
