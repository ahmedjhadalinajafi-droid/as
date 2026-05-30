import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _qiblaAngle; // true-north bearing to the Kaaba
  double _heading = 0; // smoothed TRUE heading of the device
  double _userLat = 0;
  double _userLon = 0;
  String _status = 'جارٍ تحديد الموقع...';
  bool _hasLocation = false;
  bool _aligned = false;
  bool _wasAligned = false;
  bool _noCompass = false;
  StreamSubscription<CompassEvent>? _compassSub;

  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;
  static const Color _gold = Color(0xFFC9A843);
  static const Color _navy = Color(0xFF1B3D6F);

  // Approx. magnetic declination for Baghdad (~+4.5°E, 2026).
  // The compass reports MAGNETIC north; the Qibla bearing is TRUE north —
  // adding the declination converts magnetic → true so they line up.
  static const double _declination = 4.5;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _getLocation() async {
    if (mounted) {
      setState(() {
        _status = 'جارٍ تحديد الموقع...';
        _hasLocation = false;
        _qiblaAngle = null;
        _aligned = false;
        _wasAligned = false;
      });
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _status = 'يرجى تفعيل خدمة الموقع');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _status = 'تم رفض إذن الموقع');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _status = 'يرجى منح إذن الموقع من الإعدادات');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      final angle = _calcQibla(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLon = pos.longitude;
          _qiblaAngle = angle;
          _hasLocation = true;
          _status = 'وجّه أعلى الهاتف نحو علامة الكعبة 🕋';
        });
      }
      _startCompass();
    } catch (e) {
      if (mounted) setState(() => _status = 'خطأ في تحديد الموقع');
    }
  }

  void _startCompass() {
    _compassSub?.cancel();

    final events = FlutterCompass.events;
    if (events == null) {
      // Device has no magnetometer (some tablets / iPads)
      if (mounted) {
        setState(() {
          _noCompass = true;
          _status = 'جهازك لا يحتوي على بوصلة (مستشعر مغناطيسي)';
        });
      }
      return;
    }

    _compassSub = events.listen((event) {
      if (!mounted || event.heading == null) return;

      // Convert magnetic → true north, then low-pass filter the jitter
      final raw = (event.heading! + _declination + 360) % 360;
      double diff = raw - _heading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      final step = diff * 0.25;
      final newHeading = (_heading + step + 360) % 360;
      final nowAligned = _alignedFor(newHeading);

      // Skip tiny, invisible updates → far fewer rebuilds (smoother, less battery)
      if (step.abs() < 0.5 && nowAligned == _aligned) return;

      setState(() {
        _heading = newHeading;
        _aligned = nowAligned;
      });

      // Vibrate once the moment you line up with the Qibla
      if (nowAligned && !_wasAligned) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120),
            () => HapticFeedback.mediumImpact());
      }
      _wasAligned = nowAligned;
    });
  }

  double _calcQibla(double lat, double lon) {
    final latR = lat * math.pi / 180;
    final lonR = lon * math.pi / 180;
    final kLatR = _kaabaLat * math.pi / 180;
    final kLonR = _kaabaLon * math.pi / 180;
    final dLon = kLonR - lonR;
    final y = math.sin(dLon) * math.cos(kLatR);
    final x = math.cos(latR) * math.sin(kLatR) -
        math.sin(latR) * math.cos(kLatR) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double get _needleAngle {
    if (_qiblaAngle == null) return 0;
    return (_qiblaAngle! - _heading) * math.pi / 180;
  }

  bool _alignedFor(double heading) {
    if (_qiblaAngle == null) return false;
    double diff = (heading - _qiblaAngle!).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff < 5;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Gold ONLY when you are actually facing the Qibla
    final activeColor = _aligned ? _gold : (_hasLocation ? _navy : cs.primary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getLocation,
            tooltip: 'إعادة تحديد الموقع',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fixed "facing" indicator above the compass (top = phone front)
              Icon(Icons.arrow_drop_down,
                  size: 40,
                  color: _aligned ? _gold : cs.onSurface.withOpacity(0.4)),

              // Compass — glows gold when aligned
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(_aligned ? 0.45 : 0.12),
                      blurRadius: _aligned ? 34 : 12,
                      spreadRadius: _aligned ? 8 : 0,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass rose — rotates with device heading
                      CustomPaint(
                        size: const Size(290, 290),
                        painter: _CompassPainter(
                          heading: _heading,
                          cs: cs,
                          aligned: _aligned,
                          located: _hasLocation,
                        ),
                      ),

                      if (_hasLocation) ...[
                        // Kaaba marker fixed on the OUTER ring at the Qibla bearing
                        AnimatedRotation(
                          turns: _needleAngle / (2 * math.pi),
                          duration: const Duration(milliseconds: 150),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _aligned ? _gold : _navy,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.5),
                                    blurRadius: _aligned ? 12 : 4,
                                  ),
                                ],
                              ),
                              child: const Text('🕋',
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),

                        // Central arrow — points to the Kaaba, gold when aligned
                        AnimatedRotation(
                          turns: _needleAngle / (2 * math.pi),
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.navigation,
                            size: 70,
                            color: activeColor,
                          ),
                        ),
                      ],

                      // Center pivot dot
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: activeColor.withOpacity(0.5),
                                blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Status banner: aligned / angle / nothing
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _aligned
                    ? Container(
                        key: const ValueKey('aligned'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _gold, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: _gold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'أنت متجه نحو القبلة',
                              style: TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _qiblaAngle != null
                        ? Container(
                            key: const ValueKey('angle'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'اتجاه القبلة: ${_qiblaAngle!.toStringAsFixed(1)}°',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'المسافة إلى مكة: ${_distToMecca()}',
                                  style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.55),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
              ),

              const SizedBox(height: 16),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55), fontSize: 13),
              ),

              if (!_hasLocation && !_noCompass) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text('تحديد الموقع'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _distToMecca() {
    const r = 6371.0;
    final lat1 = _userLat * math.pi / 180;
    const lat2 = _kaabaLat * math.pi / 180;
    final dLat = (_userLat - _kaabaLat) * math.pi / 180;
    final dLon = (_userLon - _kaabaLon) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return '${(2 * r * math.asin(math.sqrt(a))).toStringAsFixed(0)} كم';
  }
}

// ─── Compass Painter ─────────────────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  final double heading;
  final ColorScheme cs;
  final bool aligned;
  final bool located;
  static const Color _gold = Color(0xFFC9A843);
  static const Color _navy = Color(0xFF1B3D6F);

  _CompassPainter({
    required this.heading,
    required this.cs,
    required this.aligned,
    required this.located,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final ringColor = aligned ? _gold : (located ? _navy : cs.primary);

    // Background fill
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor.withOpacity(0.06)
        ..style = PaintingStyle.fill,
    );

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor.withOpacity(aligned ? 0.9 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4 : 2.5,
    );

    // Inner decorative ring
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..color = ringColor.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tick marks
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10 - heading) * math.pi / 180;
      final isMajor = i % 9 == 0;
      final inner = isMajor ? radius - 20 : radius - 11;
      final x1 = center.dx + inner * math.sin(angle);
      final y1 = center.dy - inner * math.cos(angle);
      final x2 = center.dx + (radius - 2) * math.sin(angle);
      final y2 = center.dy - (radius - 2) * math.cos(angle);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = isMajor
              ? ringColor.withOpacity(0.55)
              : cs.onSurface.withOpacity(0.18)
          ..strokeWidth = isMajor ? 2 : 1,
      );
    }

    // Cardinal direction labels: N E S W → ش ق ج غ
    final dirs = ['ش', 'ق', 'ج', 'غ'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * math.pi / 180;
      final x = center.dx + (radius - 26) * math.sin(angle);
      final y = center.dy - (radius - 26) * math.cos(angle);
      final tp = TextPainter(textDirection: TextDirection.rtl)
        ..text = TextSpan(
          text: dirs[i],
          style: TextStyle(
            color: i == 0 ? Colors.red : (aligned ? _gold : cs.onSurface),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
      old.aligned != aligned ||
      old.located != located;
}
