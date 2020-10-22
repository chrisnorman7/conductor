import 'package:flutter/material.dart';
import 'package:location/location.dart' show PermissionStatus;

import 'location.dart' show location;
import 'windows/loading_widget.dart';
import 'windows/nearby_stops_widget.dart';

const String appName = 'Conductor';

Future<void> main() async {
  runApp(MaterialApp(
    title: appName,
    home: LoadingWidget(),
  ));
  final bool serviceEnabled = await location.serviceEnabled();
  final PermissionStatus permissionGranted = await location.requestPermission();
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
