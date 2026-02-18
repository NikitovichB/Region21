import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Переход на главный экран через 2.2 сек
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _c.stop();
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double pulse(double t) => math.pow(math.sin(math.pi * t), 2).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;

            // triangle wave: 0..1..0
            final tri = (t < 0.5) ? (t / 0.5) : (1 - (t - 0.5) / 0.5);

            // мяч между цифрами
            final x = lerpDouble(-10, 68, tri)!;
            final yArc = -34 * (4 * tri * (1 - tri)); // дуга вверх
            final rot = t * 2 * math.pi * 1.2;

            // подпрыгивания цифр
            final bounce2 = -10 * pulse(1 - tri);
            final bounce1 = -10 * pulse(tri);

            // лёгкий fade-in
            final appear = Curves.easeOut.transform(math.min(1.0, t * 3));

            return Opacity(
              opacity: appear,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Регион ',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomLeft,
                    children: [
                      // "2"
                      Transform.translate(
                        offset: Offset(0, bounce2),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                      ),
                      // "1"
                      Transform.translate(
                        offset: Offset(42, bounce1),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                      ),
                      // мяч
                      Positioned(
                        left: 18 + x,
                        bottom: 52 + yArc,
                        child: Transform.rotate(
                          angle: rot,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withOpacity(0.35),
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          child: Image.asset(
                            'assets/ball.png',
                              width: 34,
                              height: 34,
                            ),

                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

double? lerpDouble(num a, num b, double t) => a + (b - a) * t;
