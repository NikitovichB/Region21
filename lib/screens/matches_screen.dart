import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

import 'match_details_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int tabIndex = 0; // 0 = Розклад/LIVE, 1 = Завершені
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1B14), Color(0xFF0E0F12)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _Header(
                tabIndex: tabIndex,
                onTabChanged: (v) => setState(() => tabIndex = v),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('matches')
                      .where('leagueId', isEqualTo: 'premier')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ErrorBox(
                        text: 'Не вдалося завантажити матчі\n${snapshot.error}',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.orange),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    final scheduledAndLive = docs.where((d) {
                      final status = (d['status'] ?? '').toString();
                      return status == 'scheduled' || status == 'live';
                    }).toList();

                    final finished = docs.where((d) {
                      return (d['status'] ?? '').toString() == 'finished';
                    }).toList();

                    final visible = tabIndex == 0 ? scheduledAndLive : finished;

                    visible.sort((a, b) {
                      final aStatus = (a['status'] ?? '').toString();
                      final bStatus = (b['status'] ?? '').toString();

                      if (aStatus == 'live') return -1;
                      if (bStatus == 'live') return 1;

                      final aTime = (a['startAt'] as Timestamp).toDate();
                      final bTime = (b['startAt'] as Timestamp).toDate();
                      return aTime.compareTo(bTime);
                    });

                    if (visible.isEmpty) {
                      return const Center(
                        child: Text(
                          'Поки що матчів немає',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        return _MatchCard(
                          doc: visible[i],
                          onTap: () {
                            MatchDetailsScreen.open(
                              context,
                              matchId: visible[i].id,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tabIndex,
    required this.onTabChanged,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Премʼєр-ліга',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          _TabButton(
            label: 'Розклад',
            selected: tabIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Завершені',
            selected: tabIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.orange.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.orange.withOpacity(0.35) : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: selected ? AppTheme.orange : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = (doc['status'] ?? '').toString();
    final leagueId = (doc['leagueId'] ?? '').toString();

    final homeId = (doc['homeTeamId'] ?? '').toString();
    final awayId = (doc['awayTeamId'] ?? '').toString();

    final homeScore = doc['homeScore'] ?? 0;
    final awayScore = doc['awayScore'] ?? 0;

    final start = (doc['startAt'] as Timestamp).toDate();
    final time = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    final isLive = status == 'live';
    final isFinished = status == 'finished';

    final centerText = (isLive || isFinished) ? '$homeScore : $awayScore' : time;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _LeaguePill(text: _leagueLabel(leagueId)),
                const Spacer(),
                if (isLive) const _LiveBadge(),
                if (!isLive)
                  Text(
                    isFinished ? 'Завершено' : 'Заплановано',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _TeamMini(id: homeId),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(homeId, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                Text(
                  centerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isLive ? Colors.red : Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    awayId,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                _TeamMini(id: awayId),
              ],
            ),

            if (isLive)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: const [
                    Icon(Icons.touch_app_rounded, size: 16, color: Colors.white54),
                    SizedBox(width: 6),
                    Text(
                      'Натисни для деталей LIVE',
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w800, fontSize: 12),
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

class _TeamMini extends StatelessWidget {
  const _TeamMini({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('teams').doc(id.toLowerCase()).get(),
      builder: (context, snap) {
        final logoUrl = (snap.data?.data() as Map<String, dynamic>?)?['logoUrl']?.toString();
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white10),
            image: (logoUrl != null && logoUrl.isNotEmpty)
                ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                : null,
          ),
          child: (logoUrl == null || logoUrl.isEmpty)
              ? const Icon(Icons.shield_rounded, size: 18, color: Colors.white70)
              : null,
        );
      },
    );
  }
}

class _LeaguePill extends StatelessWidget {
  const _LeaguePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.orange.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.orange.withOpacity(0.45)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.orange),
      ),
    );
  }
}

String _leagueLabel(String leagueId) {
  switch (leagueId) {
    case 'premier':
      return 'Премʼєр-ліга';
    default:
      return leagueId.isEmpty ? 'Ліга' : leagueId;
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Row(
        children: const [
          Icon(Icons.circle, size: 10, color: Colors.red),
          SizedBox(width: 6),
          Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
