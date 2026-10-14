import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of checking or requesting camera and microphone permissions.
class DevicePreviewPermissions {
  const DevicePreviewPermissions({
    required this.cameraGranted,
    required this.microphoneGranted,
    this.cameraPermanentlyDenied = false,
    this.microphonePermanentlyDenied = false,
  });

  final bool cameraGranted;
  final bool microphoneGranted;
  final bool cameraPermanentlyDenied;
  final bool microphonePermanentlyDenied;

  bool get bothGranted => cameraGranted && microphoneGranted;
  bool get eitherDenied => !cameraGranted || !microphoneGranted;

  factory DevicePreviewPermissions.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const DevicePreviewPermissions(
        cameraGranted: false,
        microphoneGranted: false,
      );
    }
    return DevicePreviewPermissions(
      cameraGranted: map['camera'] == true,
      microphoneGranted: map['microphone'] == true,
      cameraPermanentlyDenied: map['cameraPermanentlyDenied'] == true,
      microphonePermanentlyDenied: map['microphonePermanentlyDenied'] == true,
    );
  }

  @override
  String toString() =>
      'DevicePreviewPermissions(camera: $cameraGranted, mic: $microphoneGranted, camPermDenied: $cameraPermanentlyDenied, micPermDenied: $microphonePermanentlyDenied)';
}

/// Abstract service interface providing camera/microphone permission checks and camera controls.
abstract class NativeDevicePreviewService {
  Future<DevicePreviewPermissions> checkPermissions();
  Future<DevicePreviewPermissions> requestPermissions();
  Future<void> openAppSettings();
  Future<void> startCamera();
  Future<void> stopCamera();
  Future<bool> isFrontCameraAvailable();
}

/// Production implementation communicating with native Android through MethodChannel.
class MethodChannelDevicePreviewService implements NativeDevicePreviewService {
  const MethodChannelDevicePreviewService();

  static const MethodChannel _channel = MethodChannel(
    'com.truelern.app/camera_controls',
  );

  @override
  Future<DevicePreviewPermissions> checkPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkPermissions',
      );
      return DevicePreviewPermissions.fromMap(res);
    } on PlatformException {
      return const DevicePreviewPermissions(
        cameraGranted: false,
        microphoneGranted: false,
      );
    } catch (_) {
      return const DevicePreviewPermissions(
        cameraGranted: false,
        microphoneGranted: false,
      );
    }
  }

  @override
  Future<DevicePreviewPermissions> requestPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'requestPermissions',
      );
      return DevicePreviewPermissions.fromMap(res);
    } on PlatformException {
      return const DevicePreviewPermissions(
        cameraGranted: false,
        microphoneGranted: false,
      );
    } catch (_) {
      return const DevicePreviewPermissions(
        cameraGranted: false,
        microphoneGranted: false,
      );
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  @override
  Future<void> startCamera() async {
    try {
      await _channel.invokeMethod('startCamera');
    } catch (_) {}
  }

  @override
  Future<void> stopCamera() async {
    try {
      await _channel.invokeMethod('stopCamera');
    } catch (_) {}
  }

  @override
  Future<bool> isFrontCameraAvailable() async {
    try {
      final res = await _channel.invokeMethod<bool>('isFrontCameraAvailable');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }
}

/// Global provider exposing [NativeDevicePreviewService].
final devicePreviewServiceProvider = Provider<NativeDevicePreviewService>((
  ref,
) {
  return const MethodChannelDevicePreviewService();
});
