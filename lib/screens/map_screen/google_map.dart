import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_map_flutter/blocs/google_map/google_map_bloc.dart';
import 'package:google_map_flutter/elements/animated_pin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng _currentLocation;
  CameraPosition initialPosition;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoogleMapBloc, GoogleMapState>(
      listener: (context, state) {
        if (state is GoogleMapSuccess) {
          _currentLocation = state.latLng;

          setState(() {
            initialPosition = CameraPosition(
              target: _currentLocation,
              zoom: 14.4746,
            );
          });
        }
      },
      builder: (context, state) {
        if (state is GoogleMapLoading) {
          return Scaffold(
            body: Center(
              child: Container(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (state is GoogleMapSuccess) {
          return new Scaffold(
            body: initialPosition != null
                ? SafeArea(
                    child: GoogleMap(
                      compassEnabled: true,
                      mapType: MapType.normal,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      initialCameraPosition: initialPosition,
                      onCameraMove: (position) {
                        print(position.target);
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: Center(
            child: Container(
              child: Text(state.errorMessage),
            ),
          ),
        );
      },
    );
  }
}
