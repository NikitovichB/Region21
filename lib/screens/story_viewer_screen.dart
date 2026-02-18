import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.storyDuration = const Duration(seconds: 5),
  });

  final List<StoryModel> stories;
  final int initialIndex;
  final Duration storyDuration;

  /// Удобный хелпер, чтобы открывать красивым переходом
  static Future<void> open(
    BuildContext context, {
    required List<StoryModel> stories,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, __, ___) => StoryViewerScreen(
          stories: stories,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late int _index;
  bool _isHolding = false;

  StoryModel get _story => widget.stories[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.stories.length - 1);

    _controller = AnimationController(
      vsync: this,
      duration: widget.storyDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _next();
      }
    });

    _playCurrent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playCurrent() {
    _controller.stop();
    _controller.value = 0;
    if (!_isHolding) {
      _controller.forward();
    }
  }

  void _next() {
    if (!mounted) return;

    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _index++;
    });
    _playCurrent();
  }

  void _prev() {
    if (!mounted) return;

    if (_index <= 0) {
      // если хочешь: можно закрывать, если уже первая
      // Navigator.of(context).pop();
      _playCurrent();
      return;
    }

    setState(() {
      _index--;
    });
    _playCurrent();
  }

  void _onHoldStart() {
    if (_isHolding) return;
    setState(() => _isHolding = true);
    _controller.stop();
  }

  void _onHoldEnd() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    _controller.forward();
  }

  ImageProvider _imageProviderFor(StoryModel s) {
    if ((s.imageUrl ?? '').isNotEmpty) return NetworkImage(s.imageUrl!);
    if ((s.assetPath ?? '').isNotEmpty) return AssetImage(s.assetPath!);
    // запасной вариант
    return const AssetImage('assets/stadium.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final imgProvider = _imageProviderFor(_story);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          // v > 0 = вниз, v < 0 = вверх
          if (v.abs() > 250) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Картинка на весь экран
            Image(
              image: imgProvider,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, _) {
                if (frame != null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white70, size: 56),
              ),
            ),

            // затемнение
            Container(color: Colors.black.withOpacity(0.25)),

            // Зоны управления: тап слева/справа + hold
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _prev,
                    onLongPressStart: (_) => _onHoldStart(),
                    onLongPressEnd: (_) => _onHoldEnd(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _next,
                    onLongPressStart: (_) => _onHoldStart(),
                    onLongPressEnd: (_) => _onHoldEnd(),
                  ),
                ),
              ],
            ),

            // Верхняя панель (прогресс + заголовок)
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Полоски прогресса
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        return Row(
                          children: List.generate(widget.stories.length, (i) {
                            final double value;
                            if (i < _index) {
                              value = 1;
                            } else if (i > _index) {
                              value = 0;
                            } else {
                              value = _controller.value;
                            }

                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: value.clamp(0, 1),
                                    minHeight: 3.2,
                                    backgroundColor: Colors.white24,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Шапка: мини-аватар + title + close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                            image: DecorationImage(
                              image: imgProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _story.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Индикатор паузы (не обязателен, но удобно)
            if (_isHolding)
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Пауза',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
