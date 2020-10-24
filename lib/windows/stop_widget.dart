/// Provides the [StopWidget] class.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:screen_state/screen_state.dart';
import 'package:http/http.dart';

import '../api.dart';
import '../departure.dart';
import '../stop.dart';
import 'route_widget.dart';

class StopWidget extends StatefulWidget {
  @override
  const StopWidget(this.stop) : super();

  final Stop stop;

  @override
  StopWidgetState createState() => StopWidgetState(stop);
}

class StopWidgetState extends State<StopWidget> with WidgetsBindingObserver {
  StopWidgetState(this.stop) : super();

  final Stop stop;
  List<Departure> departures;
  Timer timer;
  String error;
  DateTime lastLoaded;
  Screen screen;
  StreamSubscription<ScreenStateEvent> screenStateListener;
  bool screenOn;
  AppLifecycleState appState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appState = state;
  }

  @override
  void initState() {
    super.initState();
    appState = AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    screenOn = true;
    screen = Screen();
    screenStateListener =
        screen.screenStateStream.listen((ScreenStateEvent event) {
      screenOn = event == ScreenStateEvent.SCREEN_UNLOCKED ||
          event == ScreenStateEvent.SCREEN_ON;
    });
    loadTimetable();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      loadTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (error != null) {
      child = Text(error);
    } else if (departures == null) {
      child = const Text('Loading...');
    } else if (departures.isEmpty) {
      child = const Text('No departures to show.');
    } else {
      final DateTime now = DateTime.now();
      child = ListView.builder(
        itemCount: departures.length,
        itemBuilder: (BuildContext context, int index) {
          final Departure departure = departures[index];
          DateTime when =
              departure.expectedDeparture ?? departure.aimedDeparture;
          when = DateTime(when.year, when.month, when.day, when.hour,
              when.minute, now.second);
          final Duration diff = when.difference(now);
          String state;
          switch (departure.state) {
            case DepartureStates.early:
              state = 'early';
              break;
            case DepartureStates.onTime:
              state = 'on time';
              break;
            case DepartureStates.late:
              state = 'late';
              break;
            case DepartureStates.cancelled:
              state = 'cancelled';
              break;
            default:
              state = departure.state.toString();
              break;
          }
          String difference;
          if (diff.isNegative) {
            difference =
                'Departed $state at ${when.hour.toString().padLeft(2, "0")}:${when.minute.toString().padLeft(2, "0")}';
          } else if (diff.inHours > 0) {
            difference =
                '$state at ${when.hour.toString().padLeft(2, "0")}:${when.minute.toString().padLeft(2, "0")}';
          } else if (diff.inMinutes < 1) {
            difference = 'Due ($state)';
          } else {
            difference = '${diff.inMinutes} minutes ($state)';
          }
          if (departure.mode == 'train') {
            difference =
                '$difference (platform ${departure.platform ?? "unknown"})';
          }
          return ListTile(
              isThreeLine: true,
              leading: Text('${departure.name}: ${departure.destination}'),
              subtitle: Text(difference),
              trailing: Text(departure.operator),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<RouteWidget>(
                      builder: (BuildContext context) =>
                          RouteWidget(departure, stop))));
        },
      );
    }
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(stop.name),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => setState(() {
                departures = null;
                lastLoaded = null;
                loadTimetable();
              }),
            )
          ],
        ),
        body: child);
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    screenStateListener.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> loadTimetable() async {
    final DateTime now = DateTime.now();
    if ((lastLoaded == null || now.difference(lastLoaded).inMinutes >= 1) &&
        screenOn == true &&
        mounted == true &&
        appState == AppLifecycleState.resumed) {
      lastLoaded = now;
      print('Getting data.');
      try {
        final Response r = await get(getStopUri(stop));
        final dynamic json = jsonDecode(r.body);
        final Map<String, dynamic> departureListsData =
            json['departures'] as Map<String, dynamic>;
        error = json['error'] as String;
        if (error != null) {
          return;
        }
        departures = <Departure>[];
        for (final dynamic departureListData in departureListsData.values) {
          for (final dynamic departureData
              in departureListData as List<dynamic>) {
            String name = departureData['line_name'] as String;
            final String mode = departureData['mode'] as String;
            final String origin = departureData['origin_name'] as String;
            final String destination = (departureData['direction'] ??
                departureData['destination_name']) as String;
            final String operator = departureData['operator_name'] as String;
            name ??= '$operator from $origin';
            DateTime aimedDeparture;
            final DateTime now = DateTime.now();
            final String nowDateString =
                '${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}';
            try {
              aimedDeparture = DateTime.parse(
                  '${departureData["date"] ?? nowDateString} ${departureData["aimed_departure_time"]}');
            } on FormatException {
              aimedDeparture = null;
            }
            DateTime expectedDeparture;
            try {
              expectedDeparture = DateTime.parse(
                  '${departureData["expected_departure_date"]} ${departureData["best_departure_estimate"]}');
            } on FormatException {
              expectedDeparture = null;
            }
            DepartureStates state = DepartureStates.onTime;
            String problemString;
            dynamic status = departureData['status'];
            if (status is Map) {
              final Map<String, dynamic> cancellation =
                  status['cancellation'] as Map<String, dynamic>;
              problemString = cancellation['reason'] as String;
              if (problemString != null) {
                state = DepartureStates.cancelled;
              }
            } else {
              status = status as String;
              if (status == 'EARLY') {
                state = DepartureStates.early;
              } else if (status == 'LATE') {
                state = DepartureStates.late;
              } else if (status != 'ON TIME' && status != null) {
                print(status);
              }
            }
            final String source = departureData['source'] as String;
            final String url = (departureData['id'] ??
                departureData['service_timetable']['id']) as String;
            departures.add(Departure(
                stop.type,
                name,
                mode,
                departureData['platform'] as String,
                state,
                origin,
                destination,
                operator,
                aimedDeparture,
                expectedDeparture,
                'All good',
                source,
                url));
          }
        }
      } catch (e) {
        error = e.toString();
        rethrow;
      }
    }
    setState(() {
      if (departures != null) {
        departures.sort((Departure a, Departure b) =>
            a.aimedDeparture.compareTo(b.aimedDeparture));
      }
    });
  }
}
