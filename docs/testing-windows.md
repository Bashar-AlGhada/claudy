# Windows Testing Matrix

- Windows 10 x64: unit, widget, integration tests; manual smoke run
- Windows 11 x64: unit, widget, integration tests; manual smoke run
- Windows 11 arm64: manual build and smoke run (requires local VS arm64 toolchain)

Automation:
- CI runs `flutter test` on `windows-2019` and `windows-2022` (x64).
- CI runs `flutter test -d windows integration_test -- --timeout=45m` on `windows-2019` and `windows-2022` (x64).
- Windows build workflow builds Windows x64 artifacts on `windows-2019` and `windows-2022`.

Notes:
- arm64 CI builds may not be available on GitHub-hosted runners; test locally.
- Ensure environment variables do not include secrets in diagnostics bundles.
