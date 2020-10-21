/// Stores a reference to the location object.
import 'package:location/location.dart' show Location;

Location location = Location();

/// Contains basic location information.
/// Used by bus stops, train stations, tram stops, and anything else I add in the future.
class SimpleLocation {
  SimpleLocation(this.lat, this.lon, this.accuracy);

  final double lat;
  final double lon;
  final num accuracy;
}
