import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import '../../theme/app_theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateAngle(double newAngle) {
    _animation = Tween<double>(begin: _lastAngle, end: newAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
    _lastAngle = newAngle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Compass')),
      body: FutureBuilder<bool?>(
        future: FlutterQiblah.androidDeviceSupport(),
        builder: (context, supportSnapshot) {
          return StreamBuilder<QiblahDirection>(
            stream: FlutterQiblah.qiblahStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.gold),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildUnsupported();
              }

              final data = snapshot.data!;
              final qiblahAngle = data.qiblah * (pi / 180);
              _updateAngle(qiblahAngle);

              return _buildCompass(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_rounded, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Compass not supported\non this device',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Qibla direction from Mecca:\n21.3891° N, 39.8579° E',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(QiblahDirection data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${data.qiblah.toStringAsFixed(1)}° to Qibla',
          style: const TextStyle(color: AppTheme.gold, fontSize: 18),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'Direction: ${data.direction.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: _animation,
          builder: (_, __) => Transform.rotate(
            angle: -_animation.value,
            child: _CompassWidget(qiblahAngle: _animation.value),
          ),
        ),
        const SizedBox(height: 48),
        const Text(
          '🕋  Kaaba, Mecca',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}

class _CompassWidget extends StatelessWidget {
  final double qiblahAngle;

  const _CompassWidget({required this.qiblahAngle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.surface, AppTheme.bgDark],
              ),
              border: Border.all(color: AppTheme.gold.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Cardinal directions
          ..._buildCardinals(),
          // Needle
          Transform.rotate(
            angle: qiblahAngle,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.gold, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
                Container(
                  width: 4,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardinals() {
    const labels = ['N', 'E', 'S', 'W'];
    const angles = [0.0, pi / 2, pi, 3 * pi / 2];
    const radius = 110.0;

    return List.generate(4, (i) {
      return Transform.translate(
        offset: Offset(
          radius * sin(angles[i]),
          -radius * cos(angles[i]),
        ),
        child: Text(
          labels[i],
          style: TextStyle(
            color: i == 0 ? AppTheme.gold : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });
  }
}
