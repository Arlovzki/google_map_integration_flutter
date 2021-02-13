import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:meta/meta.dart';

part 'google_map_event.dart';
part 'google_map_state.dart';

class GoogleMapBloc extends Bloc<GoogleMapEvent, GoogleMapState> {
  GoogleMapBloc() : super(GoogleMapInitial());

  final Location _location = Location();

  @override
  Stream<GoogleMapState> mapEventToState(
    GoogleMapEvent event,
  ) async* {
    if (event is GetGoogleMap) {
      yield* _mapGoogleMapToState(event);
    }
  }

  Stream<GoogleMapState> _mapGoogleMapToState(GoogleMapEvent event) async* {
    bool _serviceEnabled;
    bool _initProcess = false;
    PermissionStatus _permission;
    LocationData _locationData;

    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();

        if (_permission == PermissionStatus.GRANTED) {
          _serviceEnabled = true;
          _initProcess = true;
        } else if (!_serviceEnabled) {
          return;
        }
      }

      if (_serviceEnabled || _initProcess) {
        yield GoogleMapLoading();

        _locationData = await _location.getLocation();

        if (_locationData != null) {
          LatLng _latlng =
              LatLng(_locationData.latitude, _locationData.longitude);

          yield GoogleMapSuccess(latLng: _latlng);
        } else {
          yield GoogleMapError(errorMessage: 'Something went wrong.');
        }
      }
    } on PlatformException catch (pe) {
      print(pe.code);
      _serviceEnabled = await _location.requestService();

      if (pe.code == 'PERMISSION_DENIED') {
        yield GoogleMapDeniedError(errorMessage: pe.message);
      } else if (pe.code == 'PERMISSION_DENIED_NEVER_ASK') {
        yield GoogleMapForeverDeniedError(errorMessage: pe.message);
      } else {
        yield GoogleMapError(errorMessage: pe.message);
      }
    }
  }
}
