# Windows Smoke Checklist

Targets:
- Windows 10 x64
- Windows 11 x64
- Windows 11 arm64

## Smoke Flow

- Launch app
- Navigate: Weather → Map → Search → Settings → Weather
- Search for a city and select it; verify Weather updates
- Toggle low-power mode; verify background effects reduce/disable
- Toggle theme preset (including High contrast); verify readability
- Trigger RefreshIndicator on Weather; verify loading states and no crashes
- Map: tap to pick a coordinate; verify loading state and weather card renders
- Offline simulation: disable network; verify cached state and user-friendly messaging

## Diagnostics

- Export diagnostics from Settings → Diagnostics
- Attach the `diagnostics.json` to any bug report
