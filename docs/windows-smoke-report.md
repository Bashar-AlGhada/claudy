# Windows Smoke Report

## x64 (This Workspace)
- Build: `flutter build windows --release`
- Artifact: `build/windows/x64/runner/Release/claudy.exe`
- Launch check: process stays running after 6 seconds (no immediate crash)
- Perf: integration tests print `frameMetrics={jankCount,worstMs}` when they complete

## Windows 10/11 Coverage
- Windows 10 validation: pending manual run on a Windows 10 machine
- Windows 11 x64 validation: built and launched successfully on `10.0.26200.7462`

## arm64 Coverage
- arm64 build and smoke run: pending (requires Windows arm64 toolchain and host)
