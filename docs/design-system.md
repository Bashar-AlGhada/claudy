# Design System (Material 3)

## Tokens in use

- Spacing scale is defined in Tokens (2 to 32 spacing values).
- Corner radius comes from a single token to keep cards and controls consistent.
- Motion durations are short and shared across transitions (fast, medium, slow).
- Theme colors come from Material 3 color schemes with overlays for text readability.

## Components currently relied on

- AppCard for consistent tappable surfaces.
- AppEmptyState and AppErrorState for empty/error rendering.
- AppSkeletonBox and AppSkeletonList for loading placeholders.
- WeatherBackground for condition-aware visual treatment.

## Practical usage rules

- Use Material surfaces with focus/ripple behavior for interactive content.
- Keep animation timings consistent across screens.
- Keep loading states layout-stable to avoid jumpy UI during refresh.
- Always verify text contrast when weather backgrounds are active.
