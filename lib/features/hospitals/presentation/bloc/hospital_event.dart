import 'package:latlong2/latlong.dart';
import '../../data/models/hospital_model.dart';

abstract class HospitalEvent {}

class LoadHospitals extends HospitalEvent {}

class UpdateUserLocation extends HospitalEvent {
  final LatLng? location;
  UpdateUserLocation(this.location);
}

class UpdateHospitalsFromRemote extends HospitalEvent {}
