/// Provides the [Departure] class.

class Departure {
  Departure(
      this.name,
      this.mode,
      this.direction,
      this.operator,
      this.aimedDeparture,
      this.expectedDeparture,
      this.cancelled,
      this.source,
      this.url);

  final String name;
  final String mode;
  final String direction;
  final String operator;
  final DateTime aimedDeparture;
  final DateTime expectedDeparture;
  final String cancelled;
  final String source;
  final String url;
}
