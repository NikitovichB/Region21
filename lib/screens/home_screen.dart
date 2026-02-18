import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

import '../data/news_repository.dart';
import '../data/story_repository.dart';
import '../data/firebase_news_repository.dart';
import '../data/firebase_story_repository.dart';

import '../models/news_model.dart';
import '../models/story_model.dart';

import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ уже под Firestore
  final NewsRepository newsRepo = FirebaseNewsRepository();
  final StoryRepository storyRepo = FirebaseStoryRepository();

  late Stream<List<NewsModel>> _newsStream;
  late Stream<List<StoryModel>> _storiesStream;

  // ✅ какая новость раскрыта (id). Если null — все свернуты
  String? _expandedNewsId;

  @override
  void initState() {
    super.initState();
    _newsStream = newsRepo.watchLatest(limit: 10);
    _storiesStream = storyRepo.watchLatest(limit: 12);
  }

  void _toggleNews(String id) {
    setState(() {
      _expandedNewsId = (_expandedNewsId == id) ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/stadium.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.55)),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              const _Header(),
              const SizedBox(height: 14),

              /// ===== STORIES LIVE =====
              StreamBuilder<List<StoryModel>>(
                stream: _storiesStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _StoriesError(onRetry: () {
                      setState(() {
                        _storiesStream = storyRepo.watchLatest(limit: 12);
                      });
                    });
                  }

                  if (!snap.hasData) {
                    return const _StoriesLoading();
                  }

                  final stories = snap.data ?? const <StoryModel>[];
                  if (stories.isEmpty) return const SizedBox.shrink();

                  return _StoriesRow(
                    items: stories,
                    onTap: (story) {
                      final index = stories.indexWhere((s) => s.id == story.id);
                      StoryViewerScreen.open(
                        context,
                        stories: stories,
                        initialIndex: index < 0 ? 0 : index,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              const Text(
                'Новини',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              /// ===== NEWS LIVE =====
              StreamBuilder<List<NewsModel>>(
                stream: _newsStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _NewsError(onRetry: () {
                      setState(() {
                        _newsStream = newsRepo.watchLatest(limit: 10);
                      });
                    });
                  }

                  if (!snap.hasData) {
                    return const _NewsLoading();
                  }

                  final news = snap.data ?? const <NewsModel>[];
                  if (news.isEmpty) {
                    return const _EmptyNews();
                  }

                  return Column(
                    children: [
                      _ExpandableNewsHeroCard(
                        item: news.first,
                        isExpanded: _expandedNewsId == news.first.id,
                        onToggle: () => _toggleNews(news.first.id),
                      ),
                      const SizedBox(height: 12),
                      for (final item in news.skip(1)) ...[
                        _ExpandableNewsSmallCard(
                          item: item,
                          isExpanded: _expandedNewsId == item.id,
                          onToggle: () => _toggleNews(item.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: SvgPicture.asset(
            'assets/logo.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(text: 'REGION'),
              TextSpan(text: '21', style: TextStyle(color: AppTheme.orange)),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===== STORIES UI =====

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.items, required this.onTap});

  final List<StoryModel> items;
  final void Function(StoryModel story) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: 86,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final s = items[i];
            return _StoryBubble(
              title: s.title,
              assetPath: s.assetPath,
              imageUrl: s.imageUrl,
              onTap: () => onTap(s),
            );
          },
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.title,
    required this.onTap,
    this.assetPath,
    this.imageUrl,
  });

  final String title;
  final String? assetPath;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (assetPath != null && assetPath!.isNotEmpty) img = AssetImage(assetPath!);
    if (imageUrl != null && imageUrl!.isNotEmpty) img = NetworkImage(imageUrl!);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.orange, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                  image: img == null
                      ? null
                      : DecorationImage(
                          image: img,
                          fit: BoxFit.cover,
                          colorFilter: const ColorFilter.mode(
                            Colors.black26,
                            BlendMode.darken,
                          ),
                        ),
                ),
                child: img == null
                    ? const Icon(Icons.star_rounded, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesLoading extends StatelessWidget {
  const _StoriesLoading();

  @override
  Widget build(BuildContext context) {
    Widget bubble() => Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.25),
                border: Border.all(color: Colors.white10),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 62,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: 112,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          children: [
            bubble(),
            const SizedBox(width: 12),
            bubble(),
            const SizedBox(width: 12),
            bubble(),
            const SizedBox(width: 12),
            bubble(),
          ],
        ),
      ),
    );
  }
}

class _StoriesError extends StatelessWidget {
  const _StoriesError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Не вдалося завантажити сторіс',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Повторити',
              style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== NEWS UI (expand/collapse) =====

class _ExpandableNewsHeroCard extends StatelessWidget {
  const _ExpandableNewsHeroCard({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
  });

  final NewsModel item;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.orange.withOpacity(0.90),
              const Color(0xFFCC3D00).withOpacity(0.90),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.35),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _relative(item.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    secondChild: Text(
                      item.body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? 'Згорнути' : 'Читати',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableNewsSmallCard extends StatelessWidget {
  const _ExpandableNewsSmallCard({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
  });

  final NewsModel item;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                color: AppTheme.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    secondChild: Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _relative(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsLoading extends StatelessWidget {
  const _NewsLoading();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
        );

    return Column(
      children: [
        box(110),
        box(70),
        box(70),
      ],
    );
  }
}

class _NewsError extends StatelessWidget {
  const _NewsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Не вдалося завантажити новини',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Повторити',
              style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900),
            ),
          )
        ],
      ),
    );
  }
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Text(
        'Поки що новин немає',
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _relative(DateTime date) {
  final now = DateTime.now();
  final d = now.difference(date);

  if (d.inMinutes < 1) return 'Щойно';
  if (d.inHours < 1) return '${d.inMinutes} хв тому';
  if (d.inDays == 0) return 'Сьогодні';
  if (d.inDays == 1) return 'Вчора';
  if (d.inDays < 7) return '${d.inDays} дні тому';

  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd.$mm.${date.year}';
}
