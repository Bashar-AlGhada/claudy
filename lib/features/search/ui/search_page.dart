import 'dart:async';

import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/features/search/data/openweather_place_search_repository.dart';
import 'package:claudy/features/search/domain/models/place.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/app_skeleton.dart';
import 'package:claudy/core/ui/app_states.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  AsyncValue<List<Place>> _results = const AsyncData([]);
  List<Place> _lastPlaces = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _results = const AsyncData([]));
      return;
    }
    _debounce = Timer(Tokens.motionMedium, () async {
      final repo = ref.read(placeSearchRepositoryProvider);
      setState(() => _results = const AsyncLoading());
      final result = await repo.search(query);
      setState(() {
        _results = result.fold(
          (failure) => AsyncError(failure, StackTrace.current),
          (places) => AsyncData(places),
        );
        final next = _results.asData?.value;
        if (next != null) _lastPlaces = next;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navSearch.tr)),
      body: SafeArea(
        child: AppConstrained(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Tokens.space16),
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.searchHint.tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: _SearchResults(
                  results: _results,
                  lastPlaces: _lastPlaces,
                  query: _controller.text,
                  onPick: (place) async {
                    await ref
                        .read(locationProvider.notifier)
                        .setManualCoordinate(place.coordinate);
                    await ref
                        .read(locationProvider.notifier)
                        .setMode(LocationMode.manual);
                    if (context.mounted) context.go('/');
                  },
                  onUseCurrentLocation: () async {
                    await ref
                        .read(locationProvider.notifier)
                        .setMode(LocationMode.precise);
                    if (context.mounted) context.go('/');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.lastPlaces,
    required this.query,
    required this.onPick,
    required this.onUseCurrentLocation,
  });

  final AsyncValue<List<Place>> results;
  final List<Place> lastPlaces;
  final String query;
  final Future<void> Function(Place place) onPick;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();

    // Empty query: show current location tile + empty hint
    if (trimmed.isEmpty) {
      return ListView(
        children: [
          _CurrentLocationTile(onTap: onUseCurrentLocation),
          const Divider(height: 1),
          AppEmptyState(
            icon: Icons.search,
            title: LocaleKeys.searchEmptyHint.tr,
            body: LocaleKeys.searchHint.tr,
          ),
        ],
      );
    }

    if (results.isLoading && lastPlaces.isNotEmpty) {
      return Column(
        children: [
          const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _list(lastPlaces)),
        ],
      );
    }

    return results.when(
      data: (places) {
        if (places.isEmpty && trimmed.isNotEmpty) {
          return ListView(
            children: [
              _CurrentLocationTile(onTap: onUseCurrentLocation),
              const Divider(height: 1),
              AppEmptyState(
                icon: Icons.search_off_outlined,
                title: LocaleKeys.searchNoResults.tr,
                body: trimmed,
              ),
            ],
          );
        }
        return _list(places);
      },
      error: (e, _) => AppErrorState(message: LocaleKeys.searchError.tr),
      loading: () => Column(
        children: [
          _CurrentLocationTile(onTap: onUseCurrentLocation),
          const Divider(height: 1),
          const Expanded(child: AppSkeletonListTiles()),
        ],
      ),
    );
  }

  Widget _list(List<Place> places) {
    return ListView.separated(
      key: const PageStorageKey('search_results_list'),
      itemCount: places.length + 1,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CurrentLocationTile(onTap: onUseCurrentLocation);
        }
        final place = places[index - 1];
        return ListTile(
          title: Text(place.name),
          subtitle: Text(place.country),
          trailing: Text(LocaleKeys.searchPick.tr),
          onTap: () => onPick(place),
        );
      },
    );
  }
}

class _CurrentLocationTile extends StatelessWidget {
  const _CurrentLocationTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.my_location),
      title: Text(LocaleKeys.searchUseCurrentLocation.tr),
      subtitle: Text(LocaleKeys.searchGpsLocation.tr),
      onTap: onTap,
    );
  }
}
