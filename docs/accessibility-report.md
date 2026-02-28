# Accessibility Report (WCAG 2.1 AA Target)

## Scope
- Platforms: Windows (primary), Android/iOS (secondary)
- Screens: Weather, Details, Search, Map, Settings

## Checks

Keyboard navigation
- Focus order is logical across navigation + core screens
- Focus indicators are visible
- All interactive actions are reachable without mouse

Screen reader / semantics
- Buttons and tappable cards have labels
- Navigation destinations have readable labels
- Dynamic content updates do not cause confusing focus changes

Contrast / high contrast
- Foreground text remains readable over dynamic backgrounds via overlays
- High contrast theme preset is available in Theme settings

## Current Status
- Navigation: adaptive NavigationBar/NavigationRail labels are present
- Weather: tappable current card uses an interactive surface and announces “Details”
- Weather background: uses an overlay to support readable contrast and low-power disable

## Remaining Work
- Audit all screens with Windows Narrator and keyboard-only navigation
- Verify contrast ratios in each theme preset, especially over dynamic backgrounds
- Add any missing semantics labels/hints to custom widgets (cards, icons, charts)
