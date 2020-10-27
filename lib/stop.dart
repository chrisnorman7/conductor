/// Provides the classes required for bus, tram and train stops.
import 'labels_store.dart';
import 'location.dart';

enum StopTypes { bus, train, tram, tube }

/// The type for all stops.
///
/// The type of a stop is defined by it's type property.
class Stop {
  Stop(
    this.type,
    this.realName,
    this.location,
    this.code,
  );

  final StopTypes type;
  final String realName;
  final SimpleLocation location;
  final String code;

  String get name {
    return labels.getLabel(code) ?? realName;
  }
}
