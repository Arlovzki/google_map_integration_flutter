import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_map_flutter/blocs/google_map/google_map_bloc.dart';

final multipleProviders = [
  BlocProvider<GoogleMapBloc>(
    create: (context) => GoogleMapBloc(),
  ),
];
