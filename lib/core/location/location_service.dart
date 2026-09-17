import 'package:geolocator/geolocator.dart';

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  String get label =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} '
      '(±${accuracy.round()} m)';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
  };
}

class LocationService {
  LocationService._();

  static final instance = LocationService._();

  Future<LocationSnapshot> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Ative a localização do aparelho para continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'A permissão de localização é necessária para a rastreabilidade.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permita o acesso à localização nas configurações do aparelho.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: position.timestamp,
      );
    } catch (_) {
      throw const LocationException(
        'Não foi possível obter a localização atual. Vá para uma área aberta e tente novamente.',
      );
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
