/// Provides the [RouteWidget] class.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

import '../departure.dart';
import '../location.dart';
import '../route_stop.dart';
import '../stop.dart';
import 'stop_widget.dart';

class RouteWidget extends StatefulWidget {
  @override
  const RouteWidget(this.departure) : super();

  final Departure departure;

  @override
  RouteWidgetState createState() => RouteWidgetState(departure);
}

class RouteWidgetState extends State<RouteWidget> {
  RouteWidgetState(this.departure) : super();

  final Departure departure;
  List<RouteStop> stops;
  RouteStop origin;
  RouteStop destination;
  RouteStop nearestStop;
  StreamSubscription<LocationData> locationSubscription;

  @override
  void initState() {
    super.initState();
    loadRoute();
    locationSubscription = location.onLocationChanged.listen(updateLocation);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (stops == null) {
      child = const Text('Loading...');
    } else if (stops.isEmpty) {
      child = const Text('This route appears to be empty.');
    } else {
      child = ListView.builder(
        itemCount: stops.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Semantics(
              child: ListTile(
                leading: const Text('Nearest stop'),
                title: Text(nearestStop == null
                    ? 'Getting location...'
                    : nearestStop.stop.name),
                subtitle: Text(nearestStop == null
                    ? 'Unknown'
                    : distanceToString(nearestStop.distance)),
                isThreeLine: true,
              ),
              header: true,
              liveRegion: true,
            );
          }
          final RouteStop stop = stops[index - 1];
          String when;
          String name = stop.stop.name;
          if (stop == origin) {
            name += ' (origin stop)';
          } else if (stop == destination) {
            name += ' (destination stop)';
          }
          final Duration difference = stop.date.difference(origin.date);
          when = '${difference.isNegative ? "-" : "+"} ';
          if (difference.inHours > 0) {
            when +=
                '${difference.inHours.toString().padLeft(2, "0")}:${difference.inMinutes.toString().padLeft(2, '0')}';
          } else {
            when +=
                '${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"}';
          }
          return ListTile(
            leading: Text(name),
            title: Text(when),
            subtitle: Text(stop.distance == null
                ? 'Unknown distance'
                : distanceToString(stop.distance)),
            isThreeLine: true,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<StopWidget>(
                    builder: (BuildContext context) => StopWidget(stop.stop))),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {
              stops = null;
              loadRoute();
            }),
          )
        ],
        title: Text(departure.name),
      ),
      body: child,
    );
  }

  @override
  void dispose() {
    super.dispose();
    locationSubscription.cancel();
  }

  Future<void> loadRoute() async {
    final Response r = await get(departure.url);
    final dynamic json = jsonDecode(r.body);
    final String originCode = json['origin_atcocode'] as String;
    final List<dynamic> stopsListData = json['stops'] as List<dynamic>;
    stops = <RouteStop>[];
    for (final dynamic stopData in stopsListData) {
      DateTime date =
          DateTime.tryParse('${stopData["date"]} ${stopData["time"]}');
      date =
          DateTime(date.year, date.month, date.day, date.hour, date.minute, 0);
      SimpleLocation stopLocation;
      if (stopData['latitude'] != null) {
        stopLocation = SimpleLocation(
            stopData['latitude'] as double, stopData['longitude'] as double, 0);
      }
      final Stop stop = Stop(departure.type, stopData['stop_name'] as String,
          stopLocation, stopData['atcocode'] as String);
      final RouteStop rs = RouteStop(date, stop);
      if (rs.stop.code == originCode ||
          stop.name == (stopData['origin_name'] as String)) {
        origin = rs;
      }
      if (stop.name == stopData['destination_name'] as String) {
        destination = rs;
      }
      stops.add(rs);
    }
    setState(() {
      origin ??= stops.first;
      destination ??= stops.last;
    });
  }

  void updateLocation(LocationData data) {
    if (stops == null) {
      return;
    }
    final SimpleLocation location =
        SimpleLocation(data.latitude, data.longitude, data.accuracy.toInt());
    for (final RouteStop stop in stops) {
      final double distance = location.distanceBetween(stop.stop.location);
      if (stop.distance == null ||
          max(distance, stop.distance) - min(distance, stop.distance) >=
              data.accuracy) {
        stop.distance = distance;
        if (nearestStop == null || nearestStop.distance > stop.distance) {
          nearestStop = stop;
        }
      }
    }
    setState(() {});
  }
}
