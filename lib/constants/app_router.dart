import 'package:flutter/material.dart';
import 'package:google_map_flutter/screens/home_screen/home_screen.dart';
import 'package:google_map_flutter/screens/map_screen/gm_with_markers_polylines.dart';

import 'package:page_transition/page_transition.dart';

class AppRouter {
  static const String homeScreen = '/homeScreen';
  static const String googleMapWithMarkersPolylines =
      '/googleMapWithMarkersPolylines';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeScreen:
        return PageTransition(
          type: PageTransitionType.bottomToTop,
          child: HomeScreen(),
          curve: Curves.ease,
        );

      case googleMapWithMarkersPolylines:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: GoogleMapWithMarkersPolylines(),
          curve: Curves.ease,
        );

      default:
        return PageTransition(
          child: Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          type: PageTransitionType.fade,
        );
    }
  }
}
