import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _qiblaAngle;   // degrees from North to Qibla
  double _heading = 0;   // device compass heading (degrees)
  String _status = 'جارٍ تحديد الموقع...';
  bool _hasLocation = false;

  // Kaaba coordinates
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'يرجى تفعيل خدمة الموقع');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = 'تم رفض إذن الموقع');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'يرجى منح إذن الموقع من الإعدادات');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final angle = _calcQibla(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _qiblaAngle = angle;
          _hasLocation = true;
          _status = 'بغداد المنصور\n${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
      _listenCompass();
    } catch (e) {
      if (mounted) setState(() => _status = 'خطأ في تحديد الموقع');
    }
  }

  void _listenCompass() {
    FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() => _heading = event.heading!);
      }
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
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  // Needle angle = qiblaAngle - compassHeading
  double get _needleAngle {
    if (_qiblaAngle == null) return 0;
    return (_qiblaAngle! - _heading) * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              // Compass
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass rose background
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: _CompassPainter(
                          heading: _heading, cs: cs),
                    ),

                    // Qibla needle
                    if (_hasLocation)
                      Transform.rotate(
                        angle: _needleAngle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation,
                                size: 60, color: cs.primary),
                            const SizedBox(height: 4),
                            Text(
                              '🕋',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),

                    // Center dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Qibla angle info
              if (_qiblaAngle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'اتجاه القبلة: ${_qiblaAngle!.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المسافة إلى مكة المكرمة: ${_distToMecca()}',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),

              if (!_hasLocation) ...[
                const SizedBox(height: 16),
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
    // Approximate distance from Baghdad (33.3°N, 44.4°E) to Mecca
    const bagLat = 33.3152;
    const bagLon = 44.3661;
    const r = 6371.0;
    const lat1 = bagLat * math.pi / 180;
    const lat2 = _kaabaLat * math.pi / 180;
    const dLat = (bagLat - _kaabaLat) * math.pi / 180;
    const dLon = (bagLon - _kaabaLon) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final dist = 2 * r * math.asin(math.sqrt(a));
    return '${dist.toStringAsFixed(0)} كم';
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  final ColorScheme cs;
  _CompassPainter({required this.heading, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final circlePaint = Paint()
      ..color = cs.primary.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = cs.primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    final dirs = ['ش', 'ق', 'ج', 'غ']; // N E S W in Arabic
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * math.pi / 180;
      final x = center.dx + (radius - 22) * math.sin(angle);
      final y = center.dy - (radius - 22) * math.cos(angle);

      textPainter.text = TextSpan(
        text: dirs[i],
        style: TextStyle(
          color: i == 0 ? Colors.red : cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = cs.onSurface.withOpacity(0.3)
      ..strokeWidth = 1;
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10 - heading) * math.pi / 180;
      final inner = i % 9 == 0 ? radius - 18 : radius - 10;
      final x1 = center.dx + inner * math.sin(angle);
      final y1 = center.dy - inner * math.cos(angle);
      final x2 = center.dx + radius * math.sin(angle);
      final y2 = center.dy - radius * math.cos(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.heading != heading;
}
