import 'package:latlong2/latlong.dart';
import '../../data/models/hospital_model.dart';

abstract class HospitalState {
  final List<HospitalModel> hospitals;
  final LatLng? userLocation;
  final bool isLoading;
  final String? error;

  HospitalState({
    required this.hospitals,
    this.userLocation,
    this.isLoading = false,
    this.error,
  });
}

class HospitalInitial extends HospitalState {
  HospitalInitial() : super(hospitals: []);
}

class HospitalLoading extends HospitalState {
  HospitalLoading({required super.hospitals, super.userLocation})
    : super(isLoading: true);
}

class HospitalLoaded extends HospitalState {
  HospitalLoaded({required super.hospitals, super.userLocation});
}

class HospitalError extends HospitalState {
  HospitalError({
    required super.hospitals,
    super.userLocation,
    required super.error,
  });
}
