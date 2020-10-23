/// Stores a reference to the location object.

import 'dart:math';
import 'package:location/location.dart' show Location;

final Location location = Location();

/// A function for converting degrees to radians.
double degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

/// Contains basic location information.
/// Used by bus stops, train stations, tram stops, and anything else I add in the future.
class SimpleLocation {
  SimpleLocation(this.lat, this.lon, this.accuracy);

  final double lat;
  final double lon;
  final int accuracy;

  double distanceBetween(SimpleLocation other) {
    const double R = 6371e3; // metres
    final double fi1 = degreesToRadians(lat);
    final double fi2 = degreesToRadians(other.lat);
    final double deltaLambda = degreesToRadians(other.lon - lon);
    final double d =
        acos(sin(fi1) * sin(fi2) + cos(fi1) * cos(fi2) * cos(deltaLambda)) * R;
    final int combinedAccuracy = accuracy + other.accuracy;
    return max(0, d - combinedAccuracy);
  }
}

/// A function for returning a properly formatted distance string.
String distanceToString(double metres) {
  if (metres > 1000) {
    return '${(metres / 1000).toStringAsFixed(2)} km';
  } else {
    return '${metres.toStringAsFixed(0)} m';
  }
}
