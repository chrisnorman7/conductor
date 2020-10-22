import 'dart:convert';

/// Provides the [StopWidget] class.
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../api.dart';
import '../departure.dart';
import '../stop.dart';

class StopWidget extends StatefulWidget {
  @override
  const StopWidget(this.stop) : super();

  final Stop stop;

  @override
  StopWidgetState createState() => StopWidgetState(stop);
}

class StopWidgetState extends State<StopWidget> {
  StopWidgetState(this.stop) : super();

  final Stop stop;
  List<Departure> departures;

  @override
  Widget build(BuildContext context) {
    loadTimetable();
    return Scaffold(
        appBar: AppBar(
      leading: BackButton(
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(stop.name),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('Refresh'),
          onPressed: () => loadTimetable(),
        )
      ],
    ));
  }

  Future<void> loadTimetable() async {
    final Response r = await get(getStopUri(stop));
    final dynamic json = jsonDecode(r.body);
    final Map<String, dynamic> departureListsData =
        json['departures'] as Map<String, dynamic>;
    departures = <Departure>[];
    for (final dynamic departureListData in departureListsData.values) {
      for (final dynamic departureData in departureListData as List<dynamic>) {
        final String name = departureData['line_name'] as String;
        final String mode = departureData['mode'] as String;
        final String direction = departureData['direction'] as String;
        final String operator = departureData['operator_name'] as String;
        final DateTime aimedDeparture = DateTime.parse(
            '${departureData["date"]} ${departureData["aimed_departure_time"]}');
        DateTime expectedDeparture;
        try {
          expectedDeparture = DateTime.parse(
              '${departureData["best_expected_departure_date"]} ${departureData["best_expected_departure_time"]}');
        } on FormatException {
          print(
              '${departureData["expected_departure_date"]} ${departureData["expected_departure_time"]}');
        }
        final String cancelled =
            departureData['status']['cancellation']['reason'] as String;
        final String source = departureData['source'] as String;
        final String url = departureData['id'] as String;
        departures.add(Departure(name, mode, direction, operator,
            aimedDeparture, expectedDeparture, cancelled, source, url));
      }
    }
  }
}
