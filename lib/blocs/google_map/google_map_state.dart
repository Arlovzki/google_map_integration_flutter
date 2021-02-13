part of 'google_map_bloc.dart';

@immutable
abstract class GoogleMapState {
  final errorMessage;
  GoogleMapState({this.errorMessage = "Something is wrong!"});
}

class GoogleMapInitial extends GoogleMapState {}

class GoogleMapLoading extends GoogleMapState {}

class GoogleMapSuccess extends GoogleMapState {
  final LatLng latLng;
  GoogleMapSuccess({this.latLng});
}

class GoogleMapError extends GoogleMapState {
  final String errorMessage;
  GoogleMapError({@required this.errorMessage})
      : super(errorMessage: errorMessage);
}

class GoogleMapDeniedError extends GoogleMapState {
  final String errorMessage;
  GoogleMapDeniedError({@required this.errorMessage})
      : super(errorMessage: errorMessage);
}

class GoogleMapForeverDeniedError extends GoogleMapState {
  final String errorMessage;
  GoogleMapForeverDeniedError({@required this.errorMessage})
      : super(errorMessage: errorMessage);
}
