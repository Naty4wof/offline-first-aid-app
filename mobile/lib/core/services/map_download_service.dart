import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class MapDownloadService {
  final _store = FMTCStore('hospitalMap');

  /// Downloads a specific region for offline use.
  Stream<DownloadProgress> downloadRegion(
    LatLngBounds bounds, {
    int minZoom = 10,
    int maxZoom = 16,
  }) {
    if (kIsWeb) {
      throw UnsupportedError('FMTC bulk downloading is not supported on web.');
    }

    final region = RectangleRegion(bounds).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.offline_first_aid_app',
      ),
    );

    return _store.download.startForeground(region: region, parallelThreads: 5);
  }

  Future<int> getCachedCount() async {
    if (kIsWeb) return 0;
    final stats = await _store.stats.all;
    return stats.length;
  }

  Future<void> clearCache() async {
    if (kIsWeb) return;
    await _store.manage.reset();
  }
}
