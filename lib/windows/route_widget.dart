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
  const RouteWidget(this.departure, this.startingStop) : super();

  final Departure departure;
  final Stop startingStop;

  @override
  RouteWidgetState createState() => RouteWidgetState(departure, startingStop);
}

class RouteWidgetState extends State<RouteWidget> {
  RouteWidgetState(this.departure, this.startingStop) : super();

  final Departure departure;
  final Stop startingStop;

  String _error;
  List<RouteStop> _stops;
  RouteStop _origin;
  RouteStop _destination;
  RouteStop _nearestStop;
  StreamSubscription<LocationData> _locationSubscription;

  @override
  void initState() {
    super.initState();
    loadRoute();
    _locationSubscription = location.onLocationChanged.listen(updateLocation);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_error != null) {
      child = Text(_error);
    } else if (_stops == null) {
      child = const Text('Loading...');
    } else if (_stops.isEmpty) {
      child = const Text('This route appears to be empty.');
    } else {
      child = ListView.builder(
        itemCount: _stops.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Semantics(
              child: ListTile(
                leading: const Text('Nearest stop'),
                title: Semantics(
                  child: Text(_nearestStop == null
                      ? 'Getting location...'
                      : _nearestStop.stop.name),
                  liveRegion: true,
                ),
                subtitle: Semantics(
                    liveRegion: true,
                    child: Text(_nearestStop == null
                        ? 'Unknown'
                        : distanceToString(_nearestStop.distance))),
                isThreeLine: true,
              ),
              header: true,
            );
          }
          final RouteStop stop = _stops[index - 1];
          String name = stop.stop.name;
          int relativeIndex;
          if (_nearestStop != null) {
            relativeIndex = _stops.indexOf(stop) - _stops.indexOf(_nearestStop);
          }
          if (stop == _origin) {
            name += ' (origin stop)';
          } else if (stop == _destination) {
            name += ' (destination stop)';
          } else if (stop == _nearestStop) {
            name += ' (nearest stop)';
          } else if (relativeIndex != null) {
            if (relativeIndex == 1) {
              name += '( next stop)';
            } else if (relativeIndex == -1) {
              name += ' (previous stop)';
            }
          }
          String when;
          final Duration difference =
              stop.date.difference(_nearestStop?.date ?? _origin.date);
          when = difference.isNegative ? '-' : '';
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
            onTap: () => stop.stop == startingStop
                ? null
                : Navigator.push(
                    context,
                    MaterialPageRoute<StopWidget>(
                        builder: (BuildContext context) =>
                            StopWidget(stop.stop))),
          );
        },
      );
    }
    String name = departure.name;
    if (_origin != null) {
      name += ' from ${_origin.stop.name}';
    }
    if (_destination != null) {
      name += ' to ${_destination.stop.name}';
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
              _stops = null;
              loadRoute();
            }),
          )
        ],
        title: Text(name),
      ),
      body: child,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription.cancel();
  }

  Future<void> loadRoute() async {
    try {
      final Response r = await get(departure.url);
      final dynamic json = jsonDecode(r.body);
      _error = json['error'] as String;
      if (_error == null) {
        final String originCode = json['origin_atcocode'] as String;
        final List<dynamic> stopsListData = json['stops'] as List<dynamic>;
        _stops = <RouteStop>[];
        for (final dynamic stopData in stopsListData) {
          final String dateString = (stopData['date'] ??
              stopData['expected_departure_date'] ??
              stopData['aimed_departure_date'] ??
              stopData['aimed_arrival_date']) as String;
          final String timeString = (stopData['time'] ??
              stopData['expected_departure_time'] ??
              stopData['aimed_arrival_time'] ??
              stopData['aimed_departure_time'] ??
              stopData['expected_arrival_time']) as String;
          DateTime date = DateTime.tryParse('$dateString $timeString');
          date = DateTime(
              date.year, date.month, date.day, date.hour, date.minute, 0);
          SimpleLocation stopLocation;
          if (stopData['latitude'] != null) {
            stopLocation = SimpleLocation(stopData['latitude'] as double,
                stopData['longitude'] as double, 0);
          }
          Stop stop = Stop(
              departure.type,
              (stopData['stop_name'] ?? stopData['station_name']) as String,
              stopLocation,
              (stopData['atcocode'] ?? stopData['station_code']) as String);
          if (stop.code == startingStop.code) {
            stop = startingStop;
          }
          final RouteStop rs = RouteStop(date, stop);
          if (rs.stop.code == originCode ||
              stop.name == (stopData['origin_name'] as String)) {
            _origin = rs;
          }
          if (stop.name == stopData['destination_name'] as String) {
            _destination = rs;
          }
          _stops.add(rs);
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    setState(() {
      if (_error != null && _stops != null && _stops.isNotEmpty) {
        _origin ??= _stops.first;
        _destination ??= _stops.last;
      }
    });
  }

  void updateLocation(LocationData data) {
    if (_stops == null) {
      return;
    }
    final SimpleLocation location =
        SimpleLocation(data.latitude, data.longitude, data.accuracy.toInt());
    for (final RouteStop stop in _stops) {
      if (stop.stop.location == null) {
        continue;
      }
      final double distance = location.distanceBetween(stop.stop.location);
      if (stop.distance == null ||
          max(distance, stop.distance) - min(distance, stop.distance) >=
              data.accuracy) {
        stop.distance = distance;
        if (_nearestStop == null || _nearestStop.distance > stop.distance) {
          _nearestStop = stop;
        }
      }
    }
    setState(() {});
  }
}
