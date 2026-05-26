import 'dart:async';
import 'package:flutter/material.dart';
import 'location_service.dart';

class ProximityService extends ChangeNotifier {
  // Imam Ali Shrine, Najaf, Iraq
  static const double _shrineLatitude = 31.9961;
  static const double _shrineLongitude = 44.3087;
  static const double _thresholdMeters = 500;

  Timer? _timer;
  bool _alreadyShown = false;

  void startMonitoring(VoidCallback onNear) {
    _checkProximity(onNear);
    // Check every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkProximity(onNear);
    });
  }

  Future<void> _checkProximity(VoidCallback onNear) async {
    if (_alreadyShown) return;
    final position = await LocationService.getCurrentPosition();
    if (position == null) return;

    final distance = LocationService.distanceInMeters(
      position.latitude,
      position.longitude,
      _shrineLatitude,
      _shrineLongitude,
    );

    if (distance <= _thresholdMeters) {
      _alreadyShown = true;
      onNear();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
