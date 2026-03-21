# Performance Metrics

## Target

- Keep typical navigation and weather-screen interactions near 60fps on Windows x64.
- Validate arm64 behavior when local test hardware is available.

## Current instrumentation

- FrameMonitor logs when frame time exceeds roughly 16.7ms.
- Diagnostics export includes frame summary fields such as jankCount and worstMs.

## How to collect data

1. Launch the app on Windows.
2. Run normal flows: navigation, refresh, search, map interaction, theme toggle.
3. Export diagnostics from Settings.
4. Check logs for frame-jank warnings.
5. Inspect performance.frameTimings in diagnostics.json.

## What to record

- Device/OS/version/architecture
- Display scaling
- Scenarios tested
- Jank warning count and worst frame time

## Notes

- Use Flutter DevTools for deeper traces when warnings are repeated.
