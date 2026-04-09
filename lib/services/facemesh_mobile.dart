import 'package:flutter/services.dart';

const MethodChannel _methodChannel = MethodChannel('neuro_link/facemesh');
const EventChannel _eventChannel = EventChannel('neuro_link/gaze_stream');

void startFaceMeshNative(Function(String) onData) {
  _methodChannel.invokeMethod('start');
  _eventChannel.receiveBroadcastStream().listen((data) {
    onData(data.toString());
  });
}

void stopFaceMeshNative() {
  _methodChannel.invokeMethod('stop');
}
