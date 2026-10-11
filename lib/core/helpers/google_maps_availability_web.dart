import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool isGoogleMapsAvailable() {
  final failed = globalContext.getProperty<JSBoolean?>('messMapsAuthFailed'.toJS);
  if (failed?.toDart == true) return false;
  final google = globalContext.getProperty<JSObject?>('google'.toJS);
  final maps = google?.getProperty<JSObject?>('maps'.toJS);
  return maps?.getProperty<JSAny?>('Map'.toJS) != null;
}
