import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_map_flutter/blocs/google_map/google_map_bloc.dart';
import 'package:google_map_flutter/constants/Config.dart';
import 'package:google_map_flutter/constants/app_router.dart';
import 'package:google_map_flutter/elements/custom_primary_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:ndialog/ndialog.dart';
import 'package:place_picker/place_picker.dart' as place_picker2;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextStyle boldText = TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Google Map Integration",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomPrimaryButton(
                onPressed: () {
                  BlocProvider.of<GoogleMapBloc>(context).add(GetGoogleMap());
                  Navigator.pushNamed(context, AppRouter.googleMap);
                },
                padding: EdgeInsets.only(bottom: 8.0),
                buttonColor: Color(0xFF4285F4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.map,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Google Map',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPrimaryButton(
                onPressed: () {
                  BlocProvider.of<GoogleMapBloc>(context).add(GetGoogleMap());
                  Navigator.pushNamed(
                      context, AppRouter.googleMapWithMarkersPolylines);
                },
                padding: EdgeInsets.only(bottom: 8.0),
                buttonColor: Color(0xFFDB4437),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.maps_ugc,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Google Map w/ Markers and Polylines',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPrimaryButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlacePicker(
                        apiKey: Config.apiKey, // Put YOUR OWN KEY here.
                        onPlacePicked: (result) {
                          print(result.formattedAddress);
                          Navigator.of(context).pop();
                          _showDialog(
                            name: result.name ?? "No name",
                            location: result.formattedAddress,
                            latLng: LatLng(
                              result.geometry.location.lat,
                              result.geometry.location.lng,
                            ),
                          );
                        },

                        initialPosition: LatLng(14.3710, 120.8241),
                        useCurrentLocation: false,
                        selectInitialPosition: true,
                        searchForInitialValue: true,
                      ),
                    ),
                  );
                },
                padding: EdgeInsets.only(bottom: 8.0),
                buttonColor: Color(0xFFF4B400),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.add_road,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Google Map Picker',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPrimaryButton(
                onPressed: () async {
                  place_picker2.LocationResult result =
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => place_picker2.PlacePicker(
                                Config.apiKey,
                                displayLocation: LatLng(14.3710, 120.8241),
                              )));

                  _showDialog(
                      name: result.name,
                      location: result.formattedAddress,
                      latLng: result.latLng);
                },
                padding: EdgeInsets.only(bottom: 8.0),
                buttonColor: Color(0xFF0F9D58),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.add_location_alt,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Google Map Place Picker',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Widget> _showDialog(
      {String location, String name, LatLng latLng}) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Your selected location"),
        content: Container(
          height: MediaQuery.of(context).size.height * 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Divider(
                height: 1,
                color: Colors.grey,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Name: ", style: boldText),
                    TextSpan(text: name),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Location: ", style: boldText),
                    TextSpan(text: location),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Coordinates: ", style: boldText),
                    TextSpan(text: "${latLng.latitude}, ${latLng.longitude}"),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: RaisedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Okay, that's nice!"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
