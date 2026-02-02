import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FllTimerApp());
}

class FllTimerApp extends StatelessWidget {
  const FllTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLL TIMER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const FllTimerScreen(),
    );
  }
}

class FllTimerScreen extends StatefulWidget {
  const FllTimerScreen({super.key});

  @override
  State<FllTimerScreen> createState() => _FllTimerScreenState();
}

class _FllTimerScreenState extends State<FllTimerScreen> with SingleTickerProviderStateMixin {
  static const int totalSeconds = 150;
  int secondsLeft = totalSeconds;
  Timer? timer;

  final AudioPlayer player = AudioPlayer();
  bool started = false;
  bool played30 = false;
  bool _isFullscreen = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: totalSeconds),
      value: 1.0,
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (kIsWeb) {
        // Use dart:js to interact with the browser's Fullscreen API
        final dynamic doc = js.context['document'];
        if (_isFullscreen) {
          final dynamic docElement = doc.documentElement;
          // Try standard requestFullscreen, then vendor-prefixed versions
          if (docElement.requestFullscreen != null) {
            docElement.requestFullscreen();
          } else if (docElement.webkitRequestFullscreen != null) {
            docElement.webkitRequestFullscreen();
          } else if (docElement.msRequestFullscreen != null) {
            docElement.msRequestFullscreen();
          }
        } else {
          // Try standard exitFullscreen, then vendor-prefixed versions
          if (doc.exitFullscreen != null) {
            doc.exitFullscreen();
          } else if (doc.webkitExitFullscreen != null) {
            doc.webkitExitFullscreen();
          } else if (doc.msExitFullscreen != null) {
            doc.msExitFullscreen();
          }
        }
      } else {
        // Use Flutter's SystemChrome for mobile
        if (_isFullscreen) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      }
    });
  }

  Future<void> start() async {
    if (timer != null) return;

    if (!started) {
      started = true;
      await player.play(AssetSource('sounds/start.mp3'));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _animationController.reverse(from: secondsLeft / totalSeconds);

    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (secondsLeft == 0) {
        t.cancel();
        timer = null;
        // Play the end sound 3 times
        for (int i = 0; i < 3; i++) {
          await player.play(AssetSource('sounds/end_00.mp3'));
          if (i < 2) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        }
        return;
      }

      setState(() => secondsLeft--);

      if (secondsLeft == 30 && !played30) {
        played30 = true;
        await player.play(AssetSource('sounds/warning_30.mp3'));
      }

      if (secondsLeft == 3) {
        await player.play(AssetSource('sounds/countdown_3.mp3'));
      }
    });
  }

  void reset() {
    timer?.cancel();
    timer = null;
    started = false;
    played30 = false;
    _animationController.value = 1.0;
    setState(() => secondsLeft = totalSeconds);
  }

  String get timeText {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    _animationController.dispose();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenPadding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/unearthed_bg.jpeg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(500, 500), // Increased size
                  painter: TechCirclePainter(_animationController.value),
                  child: child,
                );
              },
              child: SizedBox(
                width: 500, // Increased size
                height: 500, // Increased size
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 110, // Increased font size
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 15.0,
                            color: Color(0xFF00E0FF),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ROBOT GAME',
                      style: TextStyle(
                        fontSize: 26, // Increased font size
                        color: const Color(0xFFFFFFFF),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenPadding.top + 20,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo_vertical.png',
                      height: 100,
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      'assets/images/logo_horizont.png',
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenPadding.bottom + 40, // Moved buttons down
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TechButton(
                  text: 'СТАРТ',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B2FF), Color(0xFF00E0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: start,
                ),
                const SizedBox(width: 20),
                _TechButton(
                  text: 'СБРОС',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: reset,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: screenPadding.bottom + 10,
            right: 10,
            child: _FullscreenButton(
              isFullscreen: _isFullscreen,
              onTap: _toggleFullscreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onTap;

  const _FullscreenButton({required this.isFullscreen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isFullscreen ? 'ВЫЙТИ' : 'ПОЛНЫЙ ЭКРАН',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechButton extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final VoidCallback onTap;

  const _TechButton({
    required this.text,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: const StadiumBorder(),
        elevation: 8,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.all(Radius.circular(80.0)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class TechCirclePainter extends CustomPainter {
  final double progress;
  TechCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 16;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Define colors
    const colorBlue = Color(0xFF00E0FF);
    const colorYellow = Color(0xFFFFD600);
    const colorRed = Color(0xFFFF4500);

    // Define transition thresholds
    const startWarningThreshold = 60 / 150.0; // at 60 seconds
    const endWarningThreshold = 55 / 150.0;   // at 55 seconds
    const dangerThreshold = 20 / 150.0;     // at 20 seconds

    final Color currentColor;

    if (progress > startWarningThreshold) {
      currentColor = colorBlue;
    } else if (progress > endWarningThreshold) {
      // Interpolate from Blue to Yellow (60s -> 55s)
      final factor = (startWarningThreshold - progress) / (startWarningThreshold - endWarningThreshold);
      currentColor = Color.lerp(colorBlue, colorYellow, factor)!;
    } else if (progress > dangerThreshold) {
      // Stay Yellow (55s -> 20s)
      currentColor = colorYellow;
    } else {
      // Interpolate from Yellow to Red (20s -> 0s)
      final factor = (dangerThreshold - progress) / dangerThreshold;
      currentColor = Color.lerp(colorYellow, colorRed, factor)!;
    }

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          currentColor,
          Color.lerp(currentColor, Colors.white, 0.5)!,
          currentColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TechCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
