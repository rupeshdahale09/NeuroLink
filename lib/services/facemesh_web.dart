import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.startFaceMesh')
external void _startFaceMesh();

@JS('window.stopFaceMesh')
external void _stopFaceMesh();

@JS('window.addEventListener')
external void _addEventListener(JSString type, JSFunction listener);

void startFaceMeshNative(Function(String) onData) {
  _startFaceMesh();
  
  _addEventListener('FaceMeshGaze'.toJS, ((JSObject event) {
    final detail = event.getProperty('detail'.toJS);
    if (detail.isA<JSString>()) {
      onData((detail as JSString).toDart);
    }
  }).toJS);
}

void stopFaceMeshNative() {
  _stopFaceMesh();
}
