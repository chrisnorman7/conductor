/// Holds information for the Transport API.
import 'stop.dart';

class AppCredentials {
  /// The app ID.
  String appId;

  // / The app key.
  String appKey;

  bool get valid {
    return appId != null && appKey != null;
  }
}

final AppCredentials credentials = AppCredentials();

/// The Hostname (or HTTPS authority)
String authority = 'transportapi.com';

/// The places URL path.
String placesPath = 'v3/uk/places.json';

/// Get a [Uri] with the app key and app ID already added.
Uri getApiUri(String path, {Map<String, String> params}) {
  params ??= <String, String>{};
  params['app_key'] = credentials.appKey;
  params['app_id'] = credentials.appId;
  return Uri.https(authority, path, params);
}

/// Get the [Uri] for any stop.
Uri getStopUri(Stop stop) {
  if (stop.type == StopTypes.train) {
    return getApiUri('/v3/uk/train/station/${stop.code}/live.json');
  } else {
    return getApiUri('/v3/uk/bus/stop/${stop.code}/live.json');
  }
}
