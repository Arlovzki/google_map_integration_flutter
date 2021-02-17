import 'dart:async';

import 'package:custom_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_place_picker/custom_place_picker.dart';
import 'package:custom_place_picker/providers/place_provider.dart';
import 'package:custom_place_picker/src/components/animated_pin.dart';
import 'package:custom_place_picker/src/components/floating_card.dart';
import 'package:custom_place_picker/src/place_picker.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'components/nearbyPlaceItem.dart';
import 'components/selectPlaceAction.dart';
import 'controllers/get_alpha_code.dart';

typedef SelectedPlaceWidgetBuilder = Widget Function(
  BuildContext context,
  PickResult selectedPlace,
  SearchingState state,
  bool isSearchBarFocused,
  List<PickResult> nearbyPlaces,
);

typedef PinBuilder = Widget Function(
  BuildContext context,
  PinState state,
);

class GoogleMapPlacePicker extends StatelessWidget {
  const GoogleMapPlacePicker({
    Key key,
    @required this.initialTarget,
    @required this.appBarKey,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.showNearbyPlaces,
    this.nearbyPlaceRadius,
    this.region,
  }) : super(key: key);

  final LatLng initialTarget;
  final GlobalKey appBarKey;
  final String region;

  final SelectedPlaceWidgetBuilder selectedPlaceWidgetBuilder;
  final PinBuilder pinBuilder;

  final ValueChanged<String> onSearchFailed;
  final VoidCallback onMoveStart;
  final MapCreatedCallback onMapCreated;
  final VoidCallback onToggleMapType;
  final VoidCallback onMyLocation;
  final ValueChanged<PickResult> onPlacePicked;

  final int debounceMilliseconds;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;

  final bool selectInitialPosition;

  final String language;

  final bool forceSearchOnZoomChanged;
  final bool hidePlaceDetailsWhenDraggingPin;
  final bool showNearbyPlaces;
  final double nearbyPlaceRadius;

  _searchByCameraLocation(PlaceProvider provider) async {
    // We don't want to search location again if camera location is changed by zooming in/out.
    bool hasZoomChanged = provider.cameraPosition != null &&
        provider.prevCameraPosition != null &&
        provider.cameraPosition.zoom != provider.prevCameraPosition.zoom;

    if (forceSearchOnZoomChanged == false && hasZoomChanged) {
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }

    provider.placeSearchingState = SearchingState.Searching;

    final GeocodingResponse response =
        await provider.geocoding.searchByLocation(
      Location(provider.cameraPosition.target.latitude,
          provider.cameraPosition.target.longitude),
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      print("Camera Location Search Error: " + response.errorMessage);
      if (onSearchFailed != null) {
        onSearchFailed(response.status);
      }
      provider.placeSearchingState = SearchingState.Idle;
      return;
    }
    if (provider.nearbyPlaceTapped == false) {
      if (usePlaceDetailSearch) {
        final PlacesDetailsResponse detailResponse =
            await provider.places.getDetailsByPlaceId(
          response.results[0].placeId,
          language: language,
        );

        if (detailResponse.errorMessage?.isNotEmpty == true ||
            detailResponse.status == "REQUEST_DENIED") {
          print("Fetching details by placeId Error: " +
              detailResponse.errorMessage);
          if (onSearchFailed != null) {
            onSearchFailed(detailResponse.status);
          }
          provider.placeSearchingState = SearchingState.Idle;
          return;
        }

        provider.selectedPlace =
            PickResult.fromPlaceDetailResult(detailResponse.result);
      } else {
        provider.selectedPlace =
            PickResult.fromGeocodingResult(response.results[0]);
      }
    }

    //* adding nearby place result
    if (showNearbyPlaces) {
      await _showNearbyPlaces(provider);
    }

    provider.placeSearchingState = SearchingState.Idle;
  }

  Future<void> _showNearbyPlaces(PlaceProvider provider) async {
    Location location = Location(provider.selectedPlace.geometry.location.lat,
        provider.selectedPlace.geometry.location.lng);

    var nearbyPlaceResult = await provider.places
        .searchNearbyWithRadius(location, nearbyPlaceRadius);
    List<PickResult> pickResults = [];
    for (PlacesSearchResult place in nearbyPlaceResult.results) {
      pickResults.add(PickResult.fromPlacesSearchResponse(place));
    }

    provider.nearbyPlaces = pickResults;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildGoogleMap(context),
        _buildPin(),
        _buildFloatingCard(),
        _buildMapIcons(context),
      ],
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    return Selector<PlaceProvider, MapType>(
        selector: (_, provider) => provider.mapType,
        builder: (_, data, __) {
          PlaceProvider provider = PlaceProvider.of(context, listen: false);
          CameraPosition initialCameraPosition =
              CameraPosition(target: initialTarget, zoom: 15);

          return Listener(
            onPointerDown: (value) {
              provider.nearbyPlaceTapped = false;
            },
            child: GoogleMap(
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              initialCameraPosition: initialCameraPosition,
              mapType: data,
              myLocationEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                provider.mapController = controller;
                provider.setCameraPosition(null);
                provider.pinState = PinState.Idle;

                // When select initialPosition set to true.
                if (selectInitialPosition) {
                  provider.setCameraPosition(initialCameraPosition);
                  _searchByCameraLocation(provider);
                }
              },

              onCameraIdle: () {
                if (provider.isAutoCompleteSearching) {
                  provider.isAutoCompleteSearching = false;
                  provider.pinState = PinState.Idle;
                  return;
                }

                // Perform search only if the setting is to true.
                if (usePinPointingSearch) {
                  // Search current camera location only if camera has mov  ed (dragged) before.
                  if (provider.pinState == PinState.Dragging) {
                    // Cancel previous timer.
                    if (provider.debounceTimer?.isActive ?? false) {
                      provider.debounceTimer.cancel();
                    }
                    provider.debounceTimer =
                        Timer(Duration(milliseconds: debounceMilliseconds), () {
                      _searchByCameraLocation(provider);
                    });
                  }
                }

                provider.pinState = PinState.Idle;
              },
              onCameraMoveStarted: () {
                provider.setPrevCameraPosition(provider.cameraPosition);

                // Cancel any other timer.
                provider.debounceTimer?.cancel();

                // Update state, dismiss keyboard and clear text.
                provider.pinState = PinState.Dragging;

                // Begins the search state if the hide details is enabled
                if (this.hidePlaceDetailsWhenDraggingPin) {
                  provider.placeSearchingState = SearchingState.Searching;
                }

                onMoveStart();
              },
              onCameraMove: (CameraPosition position) {
                provider.setCameraPosition(position);
              },
              // gestureRecognizers make it possible to navigate the map when it's a
              // child in a scroll view e.g ListView, SingleChildScrollView...
              gestureRecognizers: Set()
                ..add(Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer())),
            ),
          );
        });
  }

  Widget _buildPin() {
    return Center(
      child: Selector<PlaceProvider, PinState>(
        selector: (_, provider) => provider.pinState,
        builder: (context, state, __) {
          if (pinBuilder == null) {
            return _defaultPinBuilder(context, state);
          } else {
            return Builder(
                builder: (builderContext) => pinBuilder(builderContext, state));
          }
        },
      ),
    );
  }

  Widget _defaultPinBuilder(BuildContext context, PinState state) {
    if (state == PinState.Preparing) {
      return Container();
    } else if (state == PinState.Idle) {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.place, size: 36, color: Colors.red),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedPin(
                    child: Icon(Icons.place, size: 36, color: Colors.red)),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingCard() {
    return Selector<
        PlaceProvider,
        Tuple6<PickResult, SearchingState, bool, PinState, List<PickResult>,
            PlaceProvider>>(
      selector: (_, provider) => Tuple6(
          provider.selectedPlace,
          provider.placeSearchingState,
          provider.isSearchBarFocused,
          provider.pinState,
          provider.nearbyPlaces,
          provider),
      builder: (context, data, __) {
        if ((data.item1 == null && data.item2 == SearchingState.Idle) ||
            data.item3 == true ||
            data.item4 == PinState.Dragging &&
                this.hidePlaceDetailsWhenDraggingPin) {
          return Container();
        } else {
          if (selectedPlaceWidgetBuilder == null) {
            return _defaultPlaceWidgetBuilder(
                context, data.item1, data.item2, data.item5, data.item6);
          } else {
            return Builder(
                builder: (builderContext) => selectedPlaceWidgetBuilder(
                    builderContext,
                    data.item1,
                    data.item2,
                    data.item3,
                    data.item5));
          }
        }
      },
    );
  }

  Widget _defaultPlaceWidgetBuilder(
      BuildContext context,
      PickResult data,
      SearchingState state,
      List<PickResult> nearbyPlaces,
      PlaceProvider provider) {
    //* Mediaquery variables
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return FloatingCard(
        bottomPosition: height * 0.02,
        leftPosition: width * 0.025,
        rightPosition: width * 0.025,
        width: width * 0.9,
        height: state == SearchingState.Searching
            ? height * 0.2
            : showNearbyPlaces
                ? height * 0.45
                : height * 0.1,
        borderRadius: BorderRadius.circular(12.0),
        elevation: 4.0,
        color: Theme.of(context).cardColor,
        child: state == SearchingState.Searching
            ? _buildLoadingIndicator()
            : showNearbyPlaces
                ? _buildNearbyPlacePicker(context, provider, nearbyPlaces)
                : _buildSelectionPlacePicker(context, provider));
  }

  Widget _buildNearbyPlacePicker(BuildContext context, PlaceProvider provider,
      List<PickResult> nearbyPlaces) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectPlaceAction(provider.selectedPlace.name, () async {
            String code = await GetAlpha2Code.getCode(
                getCountry(provider.selectedPlace.formattedAddress));
            print("code: $code and region: $region");

            if (code != region) {
              provider.regionOutOfBounds = true;
              _buildShowOutBoundDialog(context, provider);
            } else {
              onPlacePicked(provider.selectedPlace);
            }
          }, "Tap to select this location.."),
          Divider(height: 8),
          Padding(
            child: Text("Nearby Places", style: TextStyle(fontSize: 16)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 0),
              children: nearbyPlaces.map((item) {
                return NearbyPlaceItem(item, () async {
                  final PlacesDetailsResponse detailResponse =
                      await provider.places.getDetailsByPlaceId(
                    item.placeId,
                    language: language,
                  );

                  provider.selectedPlace =
                      PickResult.fromPlaceDetailResult(detailResponse.result);

                  //* set to true to cancel search camera location
                  provider.nearbyPlaceTapped = true;

                  _showNearbyPlaces(provider);

                  await _moveTo(provider.selectedPlace.geometry.location.lat,
                      provider.selectedPlace.geometry.location.lng, provider);

                  // provider.selectedPlace = item;
                });
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPlacePicker(
      BuildContext context, PlaceProvider provider) {
    return Container(
      child: SelectPlaceAction(provider.selectedPlace.name, () async {
        String code = await GetAlpha2Code.getCode(
            getCountry(provider.selectedPlace.formattedAddress));
        print("code: $code and region: $region");

        if (code != region) {
          provider.regionOutOfBounds = true;
          _buildShowOutBoundDialog(context, provider);
        } else {
          onPlacePicked(provider.selectedPlace);
        }
      }, "Tap to select this location.."),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildMapIcons(BuildContext context) {
    final RenderBox appBarRenderBox =
        appBarKey.currentContext.findRenderObject();

    return Positioned(
      top: appBarRenderBox.size.height,
      right: 15,
      child: Column(
        children: <Widget>[
          enableMapTypeButton
              ? Container(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 8.0,
                    onPressed: onToggleMapType,
                    child: Icon(Icons.layers),
                  ),
                )
              : Container(),
          SizedBox(height: 10),
          enableMyLocationButton
              ? Container(
                  width: 35,
                  height: 35,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black54
                        : Colors.white,
                    elevation: 8.0,
                    onPressed: onMyLocation,
                    child: Icon(Icons.my_location),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  _moveTo(double latitude, double longitude, PlaceProvider provider) async {
    GoogleMapController controller = provider.mapController;

    if (controller == null) return;

    var position = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 16,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(position),
    );
    provider.setCameraPosition(position);

    // provider.nearbyPlaceTapped = false;
  }

  _buildShowOutBoundDialog(BuildContext context, PlaceProvider provider) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          provider.regionOutOfBounds = false;
          return true;
        },
        child: AlertDialog(
          title: Text("Location Out of Bounds"),
          content: Text(
              "You can only pick a location based on what the value of [region] parameter. "),
          actions: [
            FlatButton(
                onPressed: () {
                  provider.regionOutOfBounds = false;
                  Navigator.pop(context);
                },
                child: Text("Okay"))
          ],
        ),
      ),
    );
  }
}
