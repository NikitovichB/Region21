import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.next});

  final Widget next;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final VideoPlayerController _vc;
  bool _navigated = false;

  // ✅ Путь к видео (поменяй если нужно)
  static const String _videoAssetPath = 'assets/intro.mp4';

  @override
  void initState() {
    super.initState();

    _vc = VideoPlayerController.asset(_videoAssetPath)
      ..setLooping(false)
      ..setVolume(0.0)
      ..initialize().then((_) async {
        if (!mounted) return;

        // стартуем сразу
        await _vc.setPlaybackSpeed(1.8);
        setState(() {});
        await _vc.play();
      });

    _vc.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted || !_vc.value.isInitialized || _navigated) return;

    final pos = _vc.value.position;
    final dur = _vc.value.duration;

    // если конец (с маленьким запасом)
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 80) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_,__ , ___) => widget.next,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _vc.removeListener(_onVideoTick);
    _vc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _vc.value.isInitialized;

    // Прогресс 0..1 (для появления лого в конце)
    double progress = 0.0;
    if (initialized && _vc.value.duration.inMilliseconds > 0) {
      progress = (_vc.value.position.inMilliseconds /
              _vc.value.duration.inMilliseconds)
          .clamp(0.0, 1.0);
    }

    // ✅ Лого появляется ближе к концу (пример: после 70% видео)
    final showLogo = progress >= 0.70;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F12),
      body: Stack(
        children: [
          // ===== VIDEO BACKGROUND =====
          Positioned.fill(
            child: initialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _vc.value.size.width,
                      height: _vc.value.size.height,
                      child: VideoPlayer(_vc),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),

          // (опционально) лёгкое затемнение сверху, чтобы UI читался
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                ),
              ),
            ),
          ),

          // ===== LOGO OVERLAY (в конце) =====
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                opacity: showLogo ? 1.0 : 0.0,
                child: Center(
                  child: Image.asset(
                    'assets/intro/logo_final.png', // ✅ твой финальный логотип
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // (опционально) тап — пропустить
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _goNext,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}