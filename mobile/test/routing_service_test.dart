import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:offline_first_aid_app/core/services/routing_service.dart';

void main() {
  final routingService = RoutingService();

  group('RoutingService Tests', () {
    test('Should generate a path with 5 points', () async {
      final start = LatLng(9.03, 38.74); // Addis Ababa
      final dest = LatLng(9.05, 38.76);

      final route = await routingService.getOfflineRoute(start, dest);

      expect(route.length, equals(5));
      expect(route.first, equals(start));
      expect(route.last, equals(dest));
    });

    test('Should calculate intermediate points correctly', () async {
      final start = LatLng(10.0, 20.0);
      final dest = LatLng(12.0, 22.0);

      final route = await routingService.getOfflineRoute(start, dest);

      // Point 1: (start.lat, midLon) -> (10.0, 21.0)
      expect(route[1].latitude, equals(10.0));
      expect(route[1].longitude, equals(21.0));

      // Point 2: (midLat, midLon) -> (11.0, 21.0)
      expect(route[2].latitude, equals(11.0));
      expect(route[2].longitude, equals(21.0));
    });
  });
}
