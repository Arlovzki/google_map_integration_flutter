import 'dart:async';

import 'package:custom_place_picker/custom_place_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_map_flutter/blocs/google_map/google_map_bloc.dart';
import 'package:google_map_flutter/constants/Config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as MP;

class GoogleMapWithMarkersPolylines extends StatefulWidget {
  @override
  _GoogleMapWithMarkersPolylinesState createState() =>
      _GoogleMapWithMarkersPolylinesState();
}

class _GoogleMapWithMarkersPolylinesState
    extends State<GoogleMapWithMarkersPolylines> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng _currentLocation;
  CameraPosition initialPosition;
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  LatLng sourceLocation = LatLng(14.3710, 120.8241);
  LatLng destinationLocation = LatLng(14.3448, 120.792);
  var distanceBetweenPoints;

  void setSourceAndDestinationIcons() async {
    sourceIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    destinationIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  @override
  void initState() {
    setSourceAndDestinationIcons();
    super.initState();
  }
  

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);

    setMapPins();
    setPolylines();
  }

  void setMapPins() {
    setState(() {
      // source pin
      _markers.add(Marker(
        markerId: MarkerId("Driver"),
        position: sourceLocation,
        icon: sourceIcon,
      ));
      // destination pin
      _markers.add(Marker(
        markerId: MarkerId("Destination"),
        position: destinationLocation,
        icon: destinationIcon,
      ));
    });
  }

  setPolylines() async {
    PolylineResult result = await polylinePoints?.getRouteBetweenCoordinates(
        Config.apiKey,
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(
            destinationLocation.latitude, destinationLocation.longitude),
        travelMode: TravelMode.walking,
        optimizeWaypoints: true);
    if (result.points.isNotEmpty) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    setState(() {
      // create a Polyline instance
      // with an id, an RGB color and the list of LatLng pairs
      Polyline polyline = Polyline(
        polylineId: PolylineId("poly"),
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      // add the constructed polyline as a set of points
      // to the polyline set, which will eventually
      // end up showing up on the map
      _polylines.add(polyline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoogleMapBloc, GoogleMapState>(
      listener: (context, state) {
        if (state is GoogleMapSuccess) {
          _currentLocation = state.latLng;
          sourceLocation = _currentLocation;

          initialPosition = CameraPosition(
            target: _currentLocation,
            zoom: 13,
          );

          distanceBetweenPoints = MP.SphericalUtil.computeDistanceBetween(
                  MP.LatLng(sourceLocation.latitude, sourceLocation.longitude),
                  MP.LatLng(destinationLocation.latitude,
                      destinationLocation.longitude))
              .toStringAsFixed(2);

          print(distanceBetweenPoints);
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
                    child: Stack(
                      children: [
                        GoogleMap(
                          markers: _markers,
                          polylines: _polylines,
                          compassEnabled: true,
                          mapType: MapType.normal,
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                          initialCameraPosition: initialPosition,
                          onMapCreated: onMapCreated,
                          zoomControlsEnabled: false,
                        ),
                        FloatingCard(
                          bottomPosition:
                              MediaQuery.of(context).size.height * 0.04,
                          leftPosition:
                              MediaQuery.of(context).size.width * 0.025,
                          rightPosition:
                              MediaQuery.of(context).size.width * 0.025,
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.1,
                          borderRadius: BorderRadius.circular(12.0),
                          elevation: 4.0,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(10.0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text: "Distance: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: distanceBetweenPoints),
                                    TextSpan(
                                        text: " meters",
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
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
