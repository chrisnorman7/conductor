/// Provides the nearby stops widget.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

import '../api.dart';
import '../location.dart';
import '../stop.dart';

class NearbyStopsWidget extends StatefulWidget {
  @override
  NearbyStopsWidgetState createState() => NearbyStopsWidgetState();
}

class NearbyStopsWidgetState extends State<NearbyStopsWidget> {
  bool serviceEnabled;
  PermissionStatus permissionGranted;
  SimpleLocation currentLocation;
  Timer timer;
  String source;
  List<Stop> stops;

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen((LocationData data) {
      currentLocation =
          SimpleLocation(data.latitude, data.longitude, data.accuracy);
      if (timer == null) {
        loadStops();
        timer ??= Timer.periodic(const Duration(seconds: 30), (Timer t) {
          loadStops();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (currentLocation == null) {
      child = const Text('Getting your location...');
    } else if (serviceEnabled == null ||
        permissionGranted != PermissionStatus.granted) {
      child = const Text(
          'To function properly, this app needs location permision. Please grant location permissions in your settings app.');
    } else if (stops == null) {
      child = const Text('Loading...');
    } else {
      child = ListView.builder(
        itemCount: stops.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return ListTile(
              title: const Text('Source'),
              subtitle: Text(source),
            );
          }
          final Stop stop = stops[index - 1];
          String type;
          if (stop.type == StopTypes.bus) {
            type = 'Bus stop';
          } else if (stop.type == StopTypes.train) {
            type = 'Train station';
          } else {
            type = 'Tram stop';
          }
          return ListTile(title: Text(stop.name), subtitle: Text(type));
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stops'),
      ),
      body: child,
    );
  }

  Future<void> loadStops() async {
    serviceEnabled ??= await location.serviceEnabled();
    permissionGranted ??= await location.requestPermission();
    if (!serviceEnabled || permissionGranted != PermissionStatus.granted) {
      return;
    }
    final Uri u = Uri.https(authority, placesPath, <String, String>{
      'app_id': appId,
      'app_key': appKey,
      'lat': currentLocation.lat.toString(),
      'lon': currentLocation.lon.toString()
    });
    final Response r = await get(u);
    setState(() {
      final Map<String, dynamic> json =
          jsonDecode(r.body) as Map<String, dynamic>;
      source = json['source'] as String;
      stops = <Stop>[];
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
        if (type == StopTypes.bus ||
            type == StopTypes.tram ||
            type == StopTypes.tube) {
          code = stopData['atcocode'] as String;
          name = '$name (${stopData["description"]})';
        } else if (type == StopTypes.train) {
          code = stopData['station_code'] as String;
        } else {
          print(stopData.keys);
        }
        stops.add(Stop(
            type,
            name,
            SimpleLocation(stopData['latitude'] as double,
                stopData['longitude'] as double, stopData['accuracy'] as int),
            code));
      }
    });
  }
}
