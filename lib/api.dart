/// Holds information for the Transport API.
import 'stop.dart';

/// The app ID.
String appId = 'f1be1ef1';

// / The app key.
String appKey = '3db5787d6e2c6c5df33f12f35437c970';

/// The Hostname (or HTTPS authority)
String authority = 'transportapi.com';

/// The places URL path.
String placesPath = 'v3/uk/places.json';

/// Get a [Uri] with the app key and app ID already added.
Uri getApiUri(String path, {Map<String, String> params}) {
  params ??= <String, String>{};
  params['app_key'] = appKey;
  params['app_id'] = appId;
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
