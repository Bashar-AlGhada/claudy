import 'dart:async';

import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/features/search/data/openweather_place_search_repository.dart';
import 'package:claudy/features/search/domain/models/place.dart';
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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final repo = ref.read(placeSearchRepositoryProvider);
      setState(() => _results = const AsyncLoading());
      final result = await repo.search(value);
      setState(() {
        _results = result.fold(
          (failure) => AsyncError(failure, StackTrace.current),
          (places) => AsyncData(places),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navSearch.tr)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
              child: _results.when(
                data: (places) {
                  if (places.isEmpty && _controller.text.trim().isNotEmpty) {
                    return Center(child: Text(LocaleKeys.searchNoResults.tr));
                  }
                  return ListView.separated(
                    itemCount: places.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return ListTile(
                        title: Text(place.name),
                        subtitle: Text(place.country),
                        trailing: Text(LocaleKeys.searchPick.tr),
                        onTap: () async {
                          await ref
                              .read(locationProvider.notifier)
                              .setManualCoordinate(place.coordinate);
                          await ref
                              .read(locationProvider.notifier)
                              .setMode(LocationMode.manual);
                          if (context.mounted) context.go('/');
                        },
                      );
                    },
                  );
                },
                error: (e, _) => Center(child: Text(LocaleKeys.searchError.tr)),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
