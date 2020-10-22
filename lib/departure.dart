/// Provides the [Departure] class.

enum DepartureStates {
  early,
  onTime,
  late,
  cancelled,
}

class Departure {
  Departure(
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
