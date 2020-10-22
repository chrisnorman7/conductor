/// Provides the nearby stops widget.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

import '../api.dart';
import '../location.dart';
import '../stop.dart';
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

  SimpleLocation currentLocation;
  List<Stop> stops;
  Map<String, String> extraData;
  DateTime lastLoaded;
  String error;

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen((LocationData data) {
      currentLocation =
          SimpleLocation(data.latitude, data.longitude, data.accuracy);
      if (stops == null) {
        loadStops();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (currentLocation == null) {
      child = const Text('Getting your location...');
    } else if (serviceEnabled == false ||
        permissionStatus != PermissionStatus.granted) {
      child = const Text(
          'In order to work correctly, this app needs access to location services. Please grant location access for this app to continue.');
    } else if (stops == null) {
      child = const Text('Loading...');
    } else if (error != null) {
      child = Text(error);
    } else {
      child = ListView.builder(
        itemCount: stops.length,
        itemBuilder: (BuildContext context, int index) {
          final Stop stop = stops[index];
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
          return ListTile(
            isThreeLine: true,
            title: Text(stop.name),
            subtitle: Text('${stop.distance.toStringAsFixed(0)} m'),
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
        title: const Text('Nearby Stops'),
        actions: <Widget>[
          ElevatedButton(
              child: const Text('Data Attribution'),
              onPressed: (extraData == null || extraData.isEmpty)
                  ? null
                  : () => Navigator.push<ExtraDataWidget>(
                      context,
                      MaterialPageRoute<ExtraDataWidget>(
                          builder: (BuildContext context) =>
                              ExtraDataWidget('Data Attribution', extraData)))),
          ElevatedButton(
            child: const Text('Refresh'),
            onPressed: currentLocation == null
                ? null
                : () => setState(() {
                      stops = null;
                      extraData = null;
                      loadStops();
                    }),
          )
        ],
      ),
      body: child,
    );
  }

  Future<void> loadStops() async {
    final Uri u = getApiUri(placesPath, params: <String, String>{
      'lat': currentLocation.lat.toString(),
      'lon': currentLocation.lon.toString()
    });
    final Response r = await get(u);
    final Map<String, dynamic> json =
        jsonDecode(r.body) as Map<String, dynamic>;
    stops = <Stop>[];
    error = json['error'] as String;
    if (error == null) {
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
            stopData['distance'] as double,
            code);
        stops.add(stop);
      }
    } else {
      extraData = null;
    }
    setState(() {
      if (error == null) {
        extraData = <String, String>{};
        extraData['Source'] = json['source'] as String;
        extraData['Acknowledgements'] = json['acknowledgements'] as String;
      }
    });
  }
}
