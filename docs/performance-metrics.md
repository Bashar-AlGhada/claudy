# Performance Metrics

## Goal
- Target: sustained 60fps for typical UI interactions and animations on Windows x64 and arm64.

## Instrumentation

Frame timing
- The app logs a warning when a frame exceeds ~16.7ms via `FrameMonitor`.
- The diagnostics export includes a summary: `jankCount` and `worstMs`.

How to collect
1. Launch the app on Windows.
2. Perform typical flows: navigation, refresh, search, map tap, theme change.
3. Export diagnostics and review recent log entries for “Frame jank detected”.
4. Read `performance.frameTimings` in `diagnostics.json`.

## Reporting

Record:
- Device/OS/version/architecture
- Display scaling
- Scenarios tested
- Observed jank warnings count and worst frame time

## Notes
- For deeper analysis, use Flutter DevTools Performance view on a local run.
