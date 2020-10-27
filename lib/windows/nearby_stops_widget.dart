/// Provides the nearby stops widget.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

import '../api.dart';
import '../favourites_store.dart';
import '../location.dart';
import '../stop.dart';
import 'api_credentials_form.dart';
import 'extra_data_widget.dart';
import 'stop_widget.dart';

class NearbyStopsWidget extends StatefulWidget {
  @override
  const NearbyStopsWidget(this.serviceEnabled, this.permissionStatus);

  final bool serviceEnabled;
  final PermissionStatus permissionStatus;

  @override
  NearbyStopsWidgetState createState() =>
      NearbyStopsWidgetState(serviceEnabled, permissionStatus);
}

class NearbyStopsWidgetState extends State<NearbyStopsWidget> {
  @override
  NearbyStopsWidgetState(this.serviceEnabled, this.permissionStatus) : super();

  bool serviceEnabled;
  PermissionStatus permissionStatus;

  SimpleLocation _currentLocation;
  SimpleLocation _lastCheckedLocation;
  List<Stop> _stops;
  Map<String, String> _extraData;
  String _error;
  bool _showingFavourites = false;

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen((LocationData data) {
      _currentLocation =
          SimpleLocation(data.latitude, data.longitude, data.accuracy.floor());
      if (_extraData != null) {
        _extraData['Latitude'] = data.latitude.toStringAsFixed(2);
        _extraData['Longitude'] = data.longitude.toStringAsFixed(2);
        _extraData['GPS Accuracy'] = distanceToString(data.accuracy);
      }
      if (credentials.valid &&
          (_stops == null ||
              _lastCheckedLocation == null ||
              _lastCheckedLocation.distanceBetween(_currentLocation) > 100)) {
        loadStops();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (credentials.valid == false) {
      child = ApiCredentialsForm.explanation(context, () => loadStops());
    } else if (_error != null) {
      child = Text(_error);
    } else if (_currentLocation == null) {
      child = const Text('Getting your location...');
    } else if (serviceEnabled == false ||
        permissionStatus != PermissionStatus.granted) {
      child = const Text(
          'In order to work correctly, this app needs access to location services. Please grant location access for this app to continue.');
    } else if (_stops == null) {
      child = const Text('Loading...');
    } else {
      child = ListView.builder(
        itemCount: _stops.length,
        itemBuilder: (BuildContext context, int index) {
          final Stop stop = _stops[index];
          String type;
          if (stop.type == StopTypes.bus) {
            type = 'Bus stop';
          } else if (stop.type == StopTypes.train) {
            type = 'Train station';
          } else if (stop.type == StopTypes.tube) {
            type = 'Tube station';
          } else {
            type = 'Tram stop';
          }
          final String distance =
              distanceToString(_currentLocation.distanceBetween(stop.location));
          return ListTile(
            isThreeLine: true,
            title: Text(stop.name),
            subtitle: Text(distance),
            trailing: Text(type),
            onTap: () {
              Navigator.push<StopWidget>(
                  context,
                  MaterialPageRoute<StopWidget>(
                      builder: (BuildContext context) => StopWidget(stop)));
            },
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: ElevatedButton(
          child: const Text('Credentials'),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<ApiCredentialsForm>(
                  builder: (BuildContext context) =>
                      ApiCredentialsForm(loadStops))),
        ),
        title: Text(_showingFavourites ? 'Favourites' : 'Nearby Stops'),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.info),
              tooltip: 'Information',
              onPressed: (_extraData == null || _extraData.isEmpty)
                  ? null
                  : () => Navigator.push<ExtraDataWidget>(
                      context,
                      MaterialPageRoute<ExtraDataWidget>(
                          builder: (BuildContext context) => ExtraDataWidget(
                              'Data Attribution', _extraData)))),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: _showingFavourites ? 'Nearby Stops' : 'Favourites',
            onPressed: _showingFavourites || favourites.count > 0
                ? () => setState(() {
                      if (_showingFavourites) {
                        _showingFavourites = false;
                        loadStops();
                      } else {
                        _showingFavourites = true;
                        _stops = favourites.stops;
                      }
                    })
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _currentLocation == null
                ? null
                : () => setState(() {
                      _stops = null;
                      loadStops();
                    }),
          )
        ],
      ),
      body: child,
    );
  }

  Future<void> loadStops() async {
    _lastCheckedLocation = _currentLocation;
    final Uri u = getApiUri(placesPath, params: <String, String>{
      'lat': _currentLocation.lat.toString(),
      'lon': _currentLocation.lon.toString()
    });
    try {
      final Response r = await get(u);
      final Map<String, dynamic> json =
          jsonDecode(r.body) as Map<String, dynamic>;
      _error = json['error'] as String;
      _stops = <Stop>[];
      if (_error == null) {
        _extraData = <String, String>{};
        _extraData['Source'] = json['source'] as String;
        _extraData['Acknowledgements'] = json['acknowledgements'] as String;
        for (final dynamic data in json['member'] as List<dynamic>) {
          final Map<String, dynamic> stopData = data as Map<String, dynamic>;
          StopTypes type;
          String name = stopData['name'] as String;
          String code;
          final String t = stopData['type'] as String;
          switch (t) {
            case 'bus_stop':
              type = StopTypes.bus;
              break;
            case 'train_station':
              type = StopTypes.train;
              break;
            case 'tram_stop':
              type = StopTypes.tram;
              break;
            case 'tube_station':
              type = StopTypes.tube;
              break;
            case 'postcode':
              continue;
            default:
              print(stopData);
              continue;
          }
          if (type == StopTypes.train) {
            code = stopData['station_code'] as String;
          } else {
            code = stopData['atcocode'] as String;
            name = '$name (${stopData["description"]})';
          }
          final Stop stop = Stop(
              type,
              name,
              SimpleLocation(stopData['latitude'] as double,
                  stopData['longitude'] as double, stopData['accuracy'] as int),
              code);
          _stops.add(stop);
        }
      } else {
        _extraData = null;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    setState(() {});
  }
}
