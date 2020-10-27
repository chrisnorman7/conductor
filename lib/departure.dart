/// Provides the [Departure] class.

import 'stop.dart';

enum DepartureStates {
  early,
  onTime,
  late,
  cancelled,
  noReport,
}

class Departure {
  Departure(
      this.type,
      this.name,
      this.mode,
      this.platform,
      this.state,
      this.origin,
      this.destination,
      this.operator,
      this.aimedDeparture,
      this.expectedDeparture,
      this.problems,
      this.source,
      this.url);

  final StopTypes type;
  final String name;
  final String mode;
  final String platform;
  final DepartureStates state;
  final String origin;
  final String destination;
  final String operator;
  final DateTime aimedDeparture;
  final DateTime expectedDeparture;
  final String problems;
  final String source;
  final String url;
}
