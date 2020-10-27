/// Provides the [StopWidget] class.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:screen_state/screen_state.dart';

import '../api.dart';
import '../departure.dart';
import '../favourites_store.dart';
import '../labels_store.dart';
import '../stop.dart';
import 'label_stop_form.dart';
import 'route_widget.dart';

class StopWidget extends StatefulWidget {
  @override
  const StopWidget(this.stop) : super();

  final Stop stop;

  @override
  StopWidgetState createState() => StopWidgetState(stop);
}

class StopWidgetState extends State<StopWidget> with WidgetsBindingObserver {
  StopWidgetState(this._stop) : super();

  final Stop _stop;
  List<Departure> _departures;
  Timer _timer;
  String _error;
  DateTime _lastLoaded;
  Screen _screen;
  StreamSubscription<ScreenStateEvent> _screenStateListener;
  bool _screenOn;
  AppLifecycleState _appState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
  }

  @override
  void initState() {
    super.initState();
    _appState = AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _screenOn = true;
    _screen = Screen();
    _screenStateListener =
        _screen.screenStateStream.listen((ScreenStateEvent event) {
      _screenOn = event == ScreenStateEvent.SCREEN_UNLOCKED ||
          event == ScreenStateEvent.SCREEN_ON;
    });
    loadTimetable();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      loadTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_error != null) {
      child = Text(_error);
    } else if (_departures == null) {
      child = const Text('Loading...');
    } else if (_departures.isEmpty) {
      child = const Text('No departures to show.');
    } else {
      final DateTime now = DateTime.now();
      child = ListView.builder(
        itemCount: _departures.length,
        itemBuilder: (BuildContext context, int index) {
          final Departure departure = _departures[index];
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
              // isThreeLine: true,
              title: Text('${departure.name}: ${departure.destination}'),
              subtitle: Text(difference),
              trailing: Text(departure.operator),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<RouteWidget>(
                      builder: (BuildContext context) =>
                          RouteWidget(departure, _stop))));
        },
      );
    }
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_stop.name),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.label),
              tooltip: '${labels.hasLabel(_stop.code) ? "Edit" : "Add"} Label',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<LabelStopForm>(
                    builder: (BuildContext context) =>
                        LabelStopForm(_stop, () => setState(() {}))),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip:
                  '${favourites.isFavourite(_stop) ? "Remove" : "Add"} Favourite',
              onPressed: () => setState(() {
                if (favourites.isFavourite(_stop)) {
                  favourites.removeFavourite(_stop);
                } else {
                  favourites.addFavourite(_stop);
                }
                favourites.saveFavourites();
              }),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => setState(() {
                _departures = null;
                _lastLoaded = null;
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
    _timer.cancel();
    _screenStateListener.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> loadTimetable() async {
    final DateTime now = DateTime.now();
    if ((_lastLoaded == null || now.difference(_lastLoaded).inMinutes >= 1) &&
        _screenOn == true &&
        mounted == true &&
        _appState == AppLifecycleState.resumed) {
      _lastLoaded = now;
      try {
        final Response r = await get(getStopUri(_stop));
        final dynamic json = jsonDecode(r.body);
        final Map<String, dynamic> departureListsData =
            json['departures'] as Map<String, dynamic>;
        _error = json['error'] as String;
        if (_error != null) {
          return;
        }
        _departures = <Departure>[];
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
            _departures.add(Departure(
                _stop.type,
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
        _error = e.toString();
        rethrow;
      }
    }
    setState(() {
      if (_departures != null) {
        _departures.sort((Departure a, Departure b) =>
            a.aimedDeparture.compareTo(b.aimedDeparture));
      }
    });
  }
}
