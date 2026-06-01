import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'islamic_background.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin {
  double? _qiblaAngle;
  double _heading = 0;
  double _userLat = 0;
  double _userLon = 0;
  String _status = 'جارٍ تحديد الموقع...';
  bool _hasLocation = false;
  bool _aligned = false;
  bool _wasAligned = false;
  bool _noCompass = false;
  StreamSubscription<CompassEvent>? _compassSub;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;
  static const Color _gold  = Color(0xFFC9A843);
  static const Color _navy  = Color(0xFF1B3D6F);
  static const Color _red   = Color(0xFFE53935);
  static const double _declination = 4.5;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _getLocation();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseCtrl.dispose();
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      final angle = _calcQibla(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLon = pos.longitude;
          _qiblaAngle = angle;
          _hasLocation = true;
          _status = 'وجّه أعلى الهاتف نحو الكعبة المشرفة';
        });
      }
      _startCompass();
    } catch (_) {
      if (mounted) setState(() => _status = 'خطأ في تحديد الموقع');
    }
  }

  void _startCompass() {
    _compassSub?.cancel();
    final events = FlutterCompass.events;
    if (events == null) {
      if (mounted) setState(() {
        _noCompass = true;
        _status = 'جهازك لا يحتوي على بوصلة';
      });
      return;
    }
    _compassSub = events.listen((event) {
      if (!mounted || event.heading == null) return;
      final raw = (event.heading! + _declination + 360) % 360;
      double diff = raw - _heading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      final step = diff * 0.25;
      final newHeading = (_heading + step + 360) % 360;
      final nowAligned = _alignedFor(newHeading);
      if (step.abs() < 0.5 && nowAligned == _aligned) return;
      setState(() {
        _heading = newHeading;
        _aligned = nowAligned;
      });
      if (nowAligned && !_wasAligned) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120),
            () => HapticFeedback.mediumImpact());
      }
      _wasAligned = nowAligned;
    });
  }

  double _calcQibla(double lat, double lon) {
    final latR  = lat * math.pi / 180;
    final lonR  = lon * math.pi / 180;
    final kLatR = _kaabaLat * math.pi / 180;
    final kLonR = _kaabaLon * math.pi / 180;
    final dLon  = kLonR - lonR;
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

  String _distToMecca() {
    const r = 6371.0;
    final lat1 = _userLat * math.pi / 180;
    const lat2 = _kaabaLat * math.pi / 180;
    final dLat = (_userLat - _kaabaLat) * math.pi / 180;
    final dLon = (_userLon - _kaabaLon) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return '${(2 * r * math.asin(math.sqrt(a))).toStringAsFixed(0)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E1C) : const Color(0xFF0D1F3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('اتجاه القبلة',
            style: TextStyle(color: Colors.white, fontFamily: 'ScheherazadeNew')),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _getLocation,
            tooltip: 'إعادة تحديد الموقع',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Star-field background pattern
          Positioned.fill(
            child: CustomPaint(painter: IslamicPatternPainter(Colors.white.withOpacity(0.03))),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Location info chip ──────────────────────────────────
                if (_hasLocation)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.location_on,
                          label:
                              '${_userLat.toStringAsFixed(3)}°  ${_userLon.toStringAsFixed(3)}°',
                        ),
                        const SizedBox(width: 10),
                        _InfoChip(
                          icon: Icons.explore,
                          label: 'مكة: ${_distToMecca()}',
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Compass ─────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        final scale = _aligned ? _pulseAnim.value : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: _buildCompass(cs, isDark),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Status / bearing card ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildStatusCard(cs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(ColorScheme cs, bool isDark) {
    const size = 300.0;
    final glowColor = _aligned ? _gold : _navy.withOpacity(0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (_aligned ? _gold : _navy).withOpacity(_aligned ? 0.6 : 0.25),
            blurRadius: _aligned ? 60 : 30,
            spreadRadius: _aligned ? 10 : 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size + 30,
            height: size + 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: glowColor.withOpacity(_aligned ? 0.7 : 0.3),
                width: _aligned ? 2 : 1,
              ),
            ),
          ),

          // Main compass dial — rotates with heading
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CompassDialPainter(
                heading: _heading,
                aligned: _aligned,
                located: _hasLocation,
              ),
            ),
          ),

          if (_hasLocation) ...[
            // Kaaba marker — fixed at Qibla direction on the dial edge
            AnimatedRotation(
              turns: _needleAngle / (2 * math.pi),
              duration: const Duration(milliseconds: 150),
              child: Align(
                alignment: const Alignment(0, -0.82),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _aligned ? _gold : Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: _aligned ? _gold : Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_aligned ? _gold : Colors.white).withOpacity(0.4),
                        blurRadius: _aligned ? 16 : 6,
                      ),
                    ],
                  ),
                  child: const Text('🕋', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

            // Needle — custom painted, points toward Qibla
            AnimatedRotation(
              turns: _needleAngle / (2 * math.pi),
              duration: const Duration(milliseconds: 150),
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _NeedlePainter(aligned: _aligned),
                ),
              ),
            ),
          ],

          // Center jewel
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _aligned ? _gold : Colors.white,
                  _aligned ? _gold.withOpacity(0.5) : _navy,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_aligned ? _gold : Colors.white).withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          // "Not located" placeholder arrow
          if (!_hasLocation)
            Icon(Icons.navigation, size: 64, color: Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs) {
    if (_aligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gold.withOpacity(0.25), _gold.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.7), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: _gold, size: 26),
            const SizedBox(width: 10),
            const Text(
              'أنت متجه نحو القبلة',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'ScheherazadeNew',
              ),
            ),
          ],
        ),
      );
    }

    if (_qiblaAngle != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BearingDisplay(
                  label: 'اتجاه القبلة',
                  value: '${_qiblaAngle!.toStringAsFixed(1)}°',
                  icon: Icons.explore,
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                _BearingDisplay(
                  label: 'اتجاه الجهاز',
                  value: '${_heading.toStringAsFixed(1)}°',
                  icon: Icons.navigation,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontFamily: 'ScheherazadeNew',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
          if (!_hasLocation && !_noCompass) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _getLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('تحديد الموقع',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFC9A843)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'ScheherazadeNew',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bearing Display ──────────────────────────────────────────────────────────

class _BearingDisplay extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _BearingDisplay(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC9A843)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            )),
        Text(label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontFamily: 'ScheherazadeNew',
            )),
      ],
    );
  }
}

// ─── Compass Dial Painter ─────────────────────────────────────────────────────

class _CompassDialPainter extends CustomPainter {
  final double heading;
  final bool aligned;
  final bool located;
  static const Color _gold = Color(0xFFC9A843);
  static const Color _navy = Color(0xFF1B3D6F);

  _CompassDialPainter({
    required this.heading,
    required this.aligned,
    required this.located,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ringColor = aligned ? _gold : Colors.white;

    // ── Background circle
    canvas.drawCircle(
      c, r - 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (aligned ? _gold : _navy).withOpacity(0.18),
            const Color(0xFF060E1C).withOpacity(0.92),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // ── Outer decorative ring (double)
    for (final rr in [r - 2, r - 9]) {
      canvas.drawCircle(
        c, rr,
        Paint()
          ..color = ringColor.withOpacity(aligned ? 0.8 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = rr == r - 2 ? (aligned ? 3 : 1.5) : 1,
      );
    }

    // ── Degree tick marks (72 ticks = every 5°)
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5 - heading) * math.pi / 180;
      final isMajor  = i % 18 == 0; // 0°/90°/180°/270°
      final isMedium = i % 6  == 0; // every 30°
      final outer = r - 10;
      final inner = isMajor ? r - 32 : (isMedium ? r - 24 : r - 18);
      final p1 = Offset(
        c.dx + outer * math.sin(angle),
        c.dy - outer * math.cos(angle),
      );
      final p2 = Offset(
        c.dx + inner * math.sin(angle),
        c.dy - inner * math.cos(angle),
      );
      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = isMajor
              ? ringColor.withOpacity(0.9)
              : (isMedium
                  ? ringColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15))
          ..strokeWidth = isMajor ? 2.5 : (isMedium ? 1.5 : 0.8)
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Cardinal direction labels  ش=N  ق=E  ج=S  غ=W
    final cardinals = [
      ('ش', 0, Colors.red.shade300),
      ('ق', 90, Colors.white.withOpacity(0.8)),
      ('ج', 180, Colors.white.withOpacity(0.8)),
      ('غ', 270, Colors.white.withOpacity(0.8)),
    ];
    for (final (label, deg, color) in cardinals) {
      final angle = (deg - heading) * math.pi / 180;
      final dist = r - 48.0;
      final x = c.dx + dist * math.sin(angle);
      final y = c.dy - dist * math.cos(angle);
      final tp = TextPainter(textDirection: TextDirection.rtl)
        ..text = TextSpan(
          text: label,
          style: TextStyle(
            color: aligned && label == 'ش' ? _gold : color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // ── Inter-cardinal labels  (ش.ق / ج.ق / ج.غ / ش.غ)
    final intercardinals = ['ش.ق', 'ج.ق', 'ج.غ', 'ش.غ'];
    for (int i = 0; i < 4; i++) {
      final angle = (45 + i * 90 - heading) * math.pi / 180;
      final dist = r - 50.0;
      final x = c.dx + dist * math.sin(angle);
      final y = c.dy - dist * math.cos(angle);
      final tp = TextPainter(textDirection: TextDirection.rtl)
        ..text = TextSpan(
          text: intercardinals[i],
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // ── Inner decorative rings (Islamic feel)
    for (final rr in [r * 0.52, r * 0.44]) {
      canvas.drawCircle(
        c, rr,
        Paint()
          ..color = ringColor.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // ── 8-pointed star decoration in the inner area
    _drawStar(canvas, c, r * 0.38, ringColor.withOpacity(0.08));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outerA = i * math.pi / 4 - math.pi / 2;
      final innerA = outerA + math.pi / 8;
      final inner  = radius * 0.45;
      if (i == 0) {
        path.moveTo(
          center.dx + radius * math.cos(outerA),
          center.dy + radius * math.sin(outerA),
        );
      } else {
        path.lineTo(
          center.dx + radius * math.cos(outerA),
          center.dy + radius * math.sin(outerA),
        );
      }
      path.lineTo(
        center.dx + inner * math.cos(innerA),
        center.dy + inner * math.sin(innerA),
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CompassDialPainter old) =>
      old.heading != heading || old.aligned != aligned || old.located != located;
}

// ─── Needle Painter ───────────────────────────────────────────────────────────

class _NeedlePainter extends CustomPainter {
  final bool aligned;
  static const Color _gold = Color(0xFFC9A843);
  static const Color _red  = Color(0xFFE53935);

  _NeedlePainter({required this.aligned});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final tip    = c.dy - r * 0.60;  // Qibla tip (top)
    final base   = c.dy + r * 0.38;  // south tip (bottom)
    final wide   = 10.0;

    // South half — red (away from Qibla)
    final southPath = Path()
      ..moveTo(c.dx, base)
      ..lineTo(c.dx - wide * 0.6, c.dy + 4)
      ..lineTo(c.dx + wide * 0.6, c.dy + 4)
      ..close();
    canvas.drawPath(
      southPath,
      Paint()
        ..color = _red.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );

    // North/Qibla half — gold (points toward Kaaba)
    final northPath = Path()
      ..moveTo(c.dx, tip)
      ..lineTo(c.dx - wide, c.dy)
      ..lineTo(c.dx, c.dy + 6)
      ..lineTo(c.dx + wide, c.dy)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: aligned
              ? [_gold, _gold.withOpacity(0.7)]
              : [Colors.white, Colors.white.withOpacity(0.6)],
        ).createShader(Rect.fromLTWH(c.dx - wide, tip, wide * 2, c.dy - tip)),
    );

    // Thin centre line for precision
    canvas.drawLine(
      Offset(c.dx, tip + 4),
      Offset(c.dx, base - 4),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.aligned != aligned;
}
