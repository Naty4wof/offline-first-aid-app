import 'package:latlong2/latlong.dart';

class RoutingService {
  Future<List<LatLng>> getOfflineRoute(LatLng start, LatLng destination) async {
    // In a real app, you would use an offline routing library like Valhalla or OSRM-based solution
    // Here we simulate it by providing a realistic multi-point path between the user and hospital.

    // We add some "zig-zag" points to make it look like it's following roads.
    double midLat = (start.latitude + destination.latitude) / 2;
    double midLon = (start.longitude + destination.longitude) / 2;

    // First intermediate point
    LatLng point1 = LatLng(start.latitude, midLon);
    // Second intermediate point
    LatLng point2 = LatLng(midLat, midLon);
    // Third intermediate point
    LatLng point3 = LatLng(midLat, destination.longitude);

    return [start, point1, point2, point3, destination];
  }
}
