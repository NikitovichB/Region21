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

  // ✅ "Всі ліги" як дефолт
  String leagueId = 'all';

  // ✅ лишаємо тільки ті, що реально є
  static const _leagues = <String, String>{
    'all': 'Всі ліги',
    'premier': 'Премʼєр-ліга',
    '1': 'Перша ліга',
    '2': 'Друга ліга',
    '3': 'Третя ліга',
  };

  @override
  Widget build(BuildContext context) {
    // ✅ якщо all — то без where
    final matchesQuery = leagueId == 'all'
        ? _db.collection('matches')
        : _db.collection('matches').where('leagueId', isEqualTo: leagueId);

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
                leagueId: leagueId,
                onLeagueChanged: (v) => setState(() => leagueId = v),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: matchesQuery.snapshots(),
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
    required this.leagueId,
    required this.onLeagueChanged,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  final String leagueId;
  final ValueChanged<String> onLeagueChanged;

  // ✅ без PR і 4-ї
  static const _leagues = <String, String>{
    'all': 'Всі ліги',
    'premier': 'Премʼєр-ліга',
    '1': 'Перша ліга',
    '2': 'Друга ліга',
    '3': 'Третя ліга',
  };

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
          // ✅ ОДНА стрілка (тільки як icon у DropdownButton).
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: leagueId,
                isExpanded: true,
                isDense: true,
                dropdownColor: const Color(0xFF121318),

                // ✅ одна стрілка справа, і вона ближче до тексту
                icon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.white70),
                ),
                iconSize: 22,

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),

                items: _leagues.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    )
                    .toList(),

                onChanged: (v) {
                  if (v != null) onLeagueChanged(v);
                },
              ),
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
          border: Border.all(
            color: selected ? AppTheme.orange.withOpacity(0.35) : Colors.white10,
          ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TeamMini(teamId: homeId),
                const SizedBox(width: 10),
                Expanded(child: _TeamName(teamId: homeId, alignEnd: false)),
                Text(
                  centerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isLive ? Colors.red : Colors.white,
                  ),
                ),
                Expanded(child: _TeamName(teamId: awayId, alignEnd: true)),
                const SizedBox(width: 10),
                _TeamMini(teamId: awayId),
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
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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

class _TeamName extends StatelessWidget {
  const _TeamName({required this.teamId, required this.alignEnd});
  final String teamId;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('teams').doc(teamId).get(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final raw = (data?['name'] ?? teamId).toString();
        final name = _beautifyTeamName(raw);

        return Text(
          name,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontWeight: FontWeight.w900),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _TeamMini extends StatelessWidget {
  const _TeamMini({required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('teams').doc(teamId).get(),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.orange,
        ),
      ),
    );
  }
}

String _leagueLabel(String leagueId) {
  switch (leagueId) {
    case 'premier':
      return 'Премʼєр-ліга';
    case '1':
      return 'Перша ліга';
    case '2':
      return 'Друга ліга';
    case '3':
      return 'Третя ліга';
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
          Text(
            'LIVE',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12),
          ),
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

/// ✅ прибираємо fk_/FK/ФК, підкреслення і робимо нормальний вигляд.
/// ВАЖЛИВО: не ламаємо CamelCase (OnlyAks), тобто не робимо Title Case завжди.
String _beautifyTeamName(String s) {
  var x = s.trim();

  final lower = x.toLowerCase();
  if (lower.startsWith('fk_')) x = x.substring(3);
  if (lower.startsWith('fk ')) x = x.substring(3);
  if (lower.startsWith('фк ')) x = x.substring(3);

  x = x.replaceAll('_', ' ').trim();

  // Якщо рядок вже має великі літери (CamelCase/BrandCase) — НЕ перетворюємо.
  final hasUpper = RegExp(r'[A-ZА-ЯІЇЄҐ]').hasMatch(x);
  if (hasUpper) return x;

  // Інакше — акуратний Title Case
  final parts = x.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final titled = parts.map((p) {
    if (p.isEmpty) return p;
    if (p.length == 1) return p.toUpperCase();
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return titled;
}
