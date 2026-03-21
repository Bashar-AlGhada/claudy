# Windows Testing Matrix

## Targets

- Windows 10 x64: unit, widget, integration tests + manual smoke run
- Windows 11 x64: unit, widget, integration tests + manual smoke run
- Windows 11 arm64: manual build and smoke run (requires local Visual Studio arm64 toolchain)

## CI automation

- flutter test on windows-2019 and windows-2022 (x64)
- flutter test -d windows integration_test -- --timeout=45m on windows-2019 and windows-2022 (x64)
- Windows build workflow for x64 artifacts on windows-2019 and windows-2022

## Notes

- arm64 CI builds may not be available on GitHub-hosted runners; verify locally.
- Ensure diagnostics bundles never include secrets from environment variables.
