import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Displays the current location name prominently with optional region subtitle.
///
/// Shows a GPS indicator icon when using device location vs manual selection,
/// and provides a tap-to-refresh action.
class LocationHeader extends StatelessWidget {
  const LocationHeader({
    super.key,
    required this.locationName,
    this.regionName,
    this.isCurrentLocation = false,
    this.onRefresh,
  });

  final String locationName;
  final String? regionName;
  final bool isCurrentLocation;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space16,
        vertical: Tokens.space12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
      ),
      child: Row(
        children: [
          if (isCurrentLocation)
            Padding(
              padding: const EdgeInsets.only(right: Tokens.space8),
              child: Icon(
                Icons.my_location,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (regionName != null)
                  Text(
                    regionName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: 'Refresh location',
            ),
        ],
      ),
    );
  }
}
