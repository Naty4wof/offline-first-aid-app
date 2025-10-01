import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/hospital_repository_impl.dart';
import 'hospital_event.dart';
import 'hospital_state.dart';

class HospitalBloc extends Bloc<HospitalEvent, HospitalState> {
  final HospitalRepository repository;

  HospitalBloc(this.repository) : super(HospitalInitial()) {
    on<LoadHospitals>(_onLoadHospitals);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<UpdateHospitalsFromRemote>(_onUpdateHospitalsFromRemote);
  }

  Future<void> _onLoadHospitals(
    LoadHospitals event,
    Emitter<HospitalState> emit,
  ) async {
    emit(
      HospitalLoading(
        hospitals: state.hospitals,
        userLocation: state.userLocation,
      ),
    );
    try {
      final hospitals = await repository.getHospitals();
      emit(
        HospitalLoaded(hospitals: hospitals, userLocation: state.userLocation),
      );
    } catch (e) {
      emit(
        HospitalError(
          hospitals: state.hospitals,
          userLocation: state.userLocation,
          error: e.toString(),
        ),
      );
    }
  }

  void _onUpdateUserLocation(
    UpdateUserLocation event,
    Emitter<HospitalState> emit,
  ) {
    emit(
      HospitalLoaded(hospitals: state.hospitals, userLocation: event.location),
    );
  }

  Future<void> _onUpdateHospitalsFromRemote(
    UpdateHospitalsFromRemote event,
    Emitter<HospitalState> emit,
  ) async {
    emit(
      HospitalLoading(
        hospitals: state.hospitals,
        userLocation: state.userLocation,
      ),
    );
    try {
      await repository.updateHospitalsFromRemote();
      final hospitals = await repository.getHospitals();
      emit(
        HospitalLoaded(hospitals: hospitals, userLocation: state.userLocation),
      );
    } catch (e) {
      emit(
        HospitalError(
          hospitals: state.hospitals,
          userLocation: state.userLocation,
          error: 'Update failed: ${e.toString()}',
        ),
      );
    }
  }
}
