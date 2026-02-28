import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    required this.height,
    this.widthFactor = 1,
    this.radius = 12,
  });

  final double height;
  final double widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.surfaceVariant.withValues(alpha: 0.55);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBox(height: 140, radius: Tokens.cornerRadius),
        SizedBox(height: Tokens.space16),
        AppSkeletonBox(height: 18, widthFactor: 1),
        SizedBox(height: Tokens.space8),
        AppSkeletonBox(height: 18, widthFactor: 0.9),
        SizedBox(height: Tokens.space8),
        AppSkeletonBox(height: 18, widthFactor: 0.7),
      ],
    );
  }
}

class AppSkeletonListTile extends StatelessWidget {
  const AppSkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space16, vertical: Tokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(height: 16, widthFactor: 0.65),
          SizedBox(height: Tokens.space8),
          AppSkeletonBox(height: 12, widthFactor: 0.35),
        ],
      ),
    );
  }
}

class AppSkeletonListTiles extends StatelessWidget {
  const AppSkeletonListTiles({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => const AppSkeletonListTile(),
    );
  }
}
