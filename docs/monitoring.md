# Monitoring

## Logging Policy

- Do not log API keys or precise location.
- Prefer failure types, status codes, and coarse context for diagnostics.

## Crash Reporting

- Crash reporting is optional and should be privacy-first by default.
- Do not attach precise coordinates unless the user explicitly enables it.

## Analytics

- Treat analytics as opt-in.
- Prefer coarse, aggregated events.

## Operational Check

- Verify exported diagnostics bundles contain no secrets.
- Verify location data in logs remains coarse or absent.
- Review monitoring defaults at each release.

