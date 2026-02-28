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
        final next = _results.valueOrNull;
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
                    await ref.read(locationProvider.notifier).setManualCoordinate(place.coordinate);
                    await ref.read(locationProvider.notifier).setMode(LocationMode.manual);
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
  });

  final AsyncValue<List<Place>> results;
  final List<Place> lastPlaces;
  final String query;
  final Future<void> Function(Place place) onPick;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
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
          return AppEmptyState(title: LocaleKeys.searchNoResults.tr);
        }
        return _list(places);
      },
      error: (e, _) => AppErrorState(message: LocaleKeys.searchError.tr),
      loading: () => const AppSkeletonListTiles(),
    );
  }

  Widget _list(List<Place> places) {
    return ListView.separated(
      key: const PageStorageKey('search_results_list'),
      itemCount: places.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = places[index];
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
