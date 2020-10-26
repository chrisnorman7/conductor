/// Provides the [FavouritesStore] class.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'location.dart';
import 'stop.dart';

class FavouritesStore {
  final String _key = 'FavouriteStops';
  final Map<String, Stop> _favourites = <String, Stop>{};

  bool isFavourite(Stop stop) {
    return _favourites.containsKey(stop.code);
  }

  void addFavourite(Stop stop) {
    _favourites[stop.code] = stop;
  }

  void removeFavourite(Stop stop) {
    _favourites.remove(stop.code);
  }

  List<Stop> get stops {
    return _favourites.values.toList();
  }

  int get count {
    return stops.length;
  }

  Future<void> loadFavourites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> favouritesList = jsonDecode(data) as List<dynamic>;
      for (final dynamic stopData in favouritesList) {
        final SimpleLocation location = SimpleLocation(
            stopData['lat'] as double,
            stopData['lon'] as double,
            stopData['accuracy'] as int);
        final Stop stop = Stop(StopTypes.values[stopData['type'] as int],
            stopData['name'] as String, location, stopData['code'] as String);
        addFavourite(stop);
      }
    }
  }

  Future<void> saveFavourites() async {
    final List<Map<String, dynamic>> data = <Map<String, dynamic>>[];
    for (final Stop stop in _favourites.values) {
      final Map<String, dynamic> stopData = <String, dynamic>{
        'name': stop.name,
        'type': stop.type.index,
        'lat': stop.location.lat,
        'lon': stop.location.lon,
        'accuracy': stop.location.accuracy,
        'code': stop.code
      };
      data.add(stopData);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String s = jsonEncode(data);
    prefs.setString(_key, s);
  }
}

final FavouritesStore favourites = FavouritesStore();
