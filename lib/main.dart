import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'favourites_store.dart';
import 'location.dart' show location;
import 'windows/loading_widget.dart';
import 'windows/nearby_stops_widget.dart';

const String appName = 'Conductor';

Future<void> main() async {
  runApp(MaterialApp(
    title: appName,
    home: LoadingWidget(),
  ));
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  credentials.appId = prefs.getString('appId');
  credentials.appKey = prefs.getString('appKey');
  await favourites.loadFavourites();
  final bool serviceEnabled = await location.serviceEnabled();
  final PermissionStatus permissionGranted = await location.requestPermission();
  if (serviceEnabled == true && permissionGranted == PermissionStatus.granted) {
    await location.changeSettings(
      accuracy: LocationAccuracy.high,
    );
  }
  runApp(
    MaterialApp(
        title: appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: NearbyStopsWidget(serviceEnabled, permissionGranted)),
  );
}
