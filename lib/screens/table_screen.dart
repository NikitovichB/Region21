import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'team_screen.dart';

/// ✅ ЕКРАН "ТАБЛИЦЯ" для додатку:
/// - 3 вкладки в ОДИН РЯД: Таблиця / Плей-оф / Статистика (без білої галочки)
/// - Таблиця тягнеться з Firestore: tables/{leagueId}/rows (а не з teams)
/// - Якщо teamName/logoUrl порожні — красиво фолбекнемо на teamId
/// - Плей-оф тягнеться з Firestore: playoffs/{leagueId}/matches/{matchId}
/// - Статистика тягнеться з Firestore: players (goals/assists/yellow/red) + teams (щоб фільтрувати по лігах)
class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

enum _TopTab { table, playoff, stats }
enum _StatsTab { goals, assists, yellow, red }

class _TableScreenState extends State<TableScreen> {
  final _db = FirebaseFirestore.instance;

  static const Map<String, String> _leagues = {
    'all': 'Усі ліги',
    'premier': 'Премʼєр-ліга',
    '1': 'Перша ліга',
    '2': 'Друга ліга',
    '3': 'Третя ліга',
  };

  _TopTab topTab = _TopTab.table;
  _StatsTab statsTab = _StatsTab.goals;

  String selectedLeague = 'all';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ ФОН
        Positioned.fill(
          child: Image.asset(
            'assets/back.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.55)),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ✅ ТРИ КНОПКИ В ОДИН РЯД (без галочки)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopTabBtn(
                        text: 'Таблиця',
                        selected: topTab == _TopTab.table,
                        onTap: () => setState(() => topTab = _TopTab.table),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TopTabBtn(
                        text: 'Плей-оф',
                        selected: topTab == _TopTab.playoff,
                        onTap: () => setState(() => topTab = _TopTab.playoff),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TopTabBtn(
                        text: 'Статистика',
                        selected: topTab == _TopTab.stats,
                        onTap: () => setState(() => topTab = _TopTab.stats),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ ВИБІР ЛІГИ (для Таблиці / Плей-оф / Статистики)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _LeagueDropdown(
                  value: selectedLeague,
                  onChanged: (v) => setState(() => selectedLeague = v),
                ),
              ),

              // ✅ КОНТЕНТ
              Expanded(
                child: Builder(
                  builder: (_) {
                    switch (topTab) {
                      case _TopTab.table:
                        return _LeagueTablesView(
                          db: _db,
                          selectedLeague: selectedLeague,
                          leagues: _leagues,
                        );
                      case _TopTab.playoff:
                      return _PlayoffView(
                          db: _db,
                          selectedLeague: selectedLeague,
                          leagues: _leagues,
                        );
                      case _TopTab.stats:
                        return _StatsView(
                          db: _db,
                          selectedLeague: selectedLeague,
                          leagues: _leagues,
                          tab: statsTab,
                          onTabChanged: (t) => setState(() => statsTab = t),
                        );
                    }
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

// ---------------------------
// ✅ TOP TAB BUTTON (без галочки, з підсвіткою/світінням)
// ---------------------------
class _TopTabBtn extends StatelessWidget {
  const _TopTabBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFF8A00).withOpacity(0.22) : Colors.black.withOpacity(0.28);
    final border = selected ? const Color(0xFFFF8A00).withOpacity(0.85) : Colors.white.withOpacity(0.10);
    final fg = selected ? const Color(0xFFFF8A00) : Colors.white.withOpacity(0.80);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8A00).withOpacity(0.20),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// ✅ LEAGUE DROPDOWN
// ---------------------------
class _LeagueDropdown extends StatelessWidget {
  const _LeagueDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const Map<String, String> _leagues = {
    'all': 'Усі ліги',
    'premier': 'Премʼєр-ліга',
    '1': 'Перша ліга',
    '2': 'Друга ліга',
    '3': 'Третя ліга',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF121318),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: _leagues.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}
// ============================================================================
// ✅ TAB 1: ТАБЛИЦЯ (з Firestore tables/{leagueId}/rows)
// ============================================================================
class _LeagueTablesView extends StatelessWidget {
  const _LeagueTablesView({
    required this.db,
    required this.selectedLeague,
    required this.leagues,
  });

  final FirebaseFirestore db;
  final String selectedLeague;
  final Map<String, String> leagues;

  @override
  Widget build(BuildContext context) {
    final showAll = selectedLeague == 'all';
    final order = const ['premier', '1', '2', '3'];

    if (!showAll) {
      return _LeagueTableBlock(
        db: db,
        leagueId: selectedLeague,
        leagueTitle: leagues[selectedLeague] ?? selectedLeague,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 160),
      children: order
          .map(
            (leagueId) => _LeagueTableBlock(
              db: db,
              leagueId: leagueId,
              leagueTitle: leagues[leagueId] ?? leagueId,
            ),
          )
          .toList(),
    );
  }
}

class _LeagueTableBlock extends StatelessWidget {
  const _LeagueTableBlock({
    required this.db,
    required this.leagueId,
    required this.leagueTitle,
  });

  final FirebaseFirestore db;
  final String leagueId;
  final String leagueTitle;

  @override
  Widget build(BuildContext context) {
    // ✅ Беремо rows таблиці цієї ліги
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('tables').doc(leagueId).collection('rows').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _GlassBlock(
            title: leagueTitle,
            child: Text(
              'Помилка таблиці: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
            ),
          );
        }
        if (!snap.hasData) {
          return _GlassBlock(
            title: leagueTitle,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          // якщо таблиця ще не збудована — просто не показуємо порожню
          return const SizedBox.shrink();
        }

        final rows = docs.map((d) {
          final data = d.data();
          return _TableRowLite(
            teamId: (data['teamId'] ?? d.id).toString(),
            teamName: (data['teamName'] ?? '').toString(),
            logoUrl: (data['logoUrl'] ?? '').toString(),
            played: _toInt(data['played']),
            wins: _toInt(data['wins']),
            draws: _toInt(data['draws']),
            losses: _toInt(data['losses']),
            gf: _toInt(data['gf']),
            ga: _toInt(data['ga']),
            gd: _toInt(data['gd']),
            points: _toInt(data['points']),
          );
        }).toList();

        // ✅ Сортування як у футболі: очки, різниця, забиті, назва
        rows.sort((a, b) {
          final p = b.points.compareTo(a.points);
          if (p != 0) return p;
          final gd = b.gd.compareTo(a.gd);
          if (gd != 0) return gd;
          final gf = b.gf.compareTo(a.gf);
          if (gf != 0) return gf;
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        });

        return _GlassBlock(
          title: leagueTitle,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const _TableHeader(),
              const SizedBox(height: 8),
              ...rows.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final r = entry.value;
                return _TeamRow(
                  index: index,
                  teamId: r.teamId,
                  teamName: r.displayName,
                  logoUrl: r.logoUrl,
                  played: r.played,
                  wins: r.wins,
                  draws: r.draws,
                  losses: r.losses,
                  goalsFor: r.gf,
                  goalsAgainst: r.ga,
                  points: r.points,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _GlassBlock extends StatelessWidget {
  const _GlassBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF8A00),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontWeight: FontWeight.w900,
      color: Colors.white70,
      fontSize: 12,
    );

    return const Row(
      children: [
        SizedBox(width: 20, child: Text('#', style: style)),
        Expanded(flex: 7, child: Text('Клуб', style: style)),
        _HCell('І'),
        _HCell('В'),
        _HCell('Н'),
        _HCell('П'),
        SizedBox(width: 44, child: Text('Г', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 26, child: Text('О', textAlign: TextAlign.end, style: style)),
      ],
    );
  }
}

class _HCell extends StatelessWidget {
  const _HCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontWeight: FontWeight.w900,
      color: Colors.white70,
      fontSize: 12,
    );
    return SizedBox(width: 22, child: Text(text, textAlign: TextAlign.center, style: style));
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.index,
    required this.teamId,
    required this.teamName,
    required this.logoUrl,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  final int index;
  final String teamId;
  final String teamName;
  final String logoUrl;
  final int played, wins, draws, losses, goalsFor, goalsAgainst, points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            flex: 7,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => TeamScreen.open(context, teamId: teamId),
              child: Row(
                children: [
                  _LogoCircle(url: logoUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teamName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Cell('$played'),
          _Cell('$wins'),
          _Cell('$draws'),
          _Cell('$losses'),
          SizedBox(
            width: 44,
            child: Text(
              '$goalsFor:$goalsAgainst',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$points',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        image: hasUrl ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: hasUrl ? null : const Icon(Icons.shield_rounded, size: 15, color: Colors.white70),
    );
  }
}

class _TableRowLite {
  _TableRowLite({
    required this.teamId,
    required this.teamName,
    required this.logoUrl,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.points,
  });

  final String teamId;
  final String teamName;
  final String logoUrl;

  final int played, wins, draws, losses, gf, ga, gd, points;

  String get displayName {
    final tn = teamName.trim();
    if (tn.isNotEmpty) return _beautifyTeamName(tn);
    return _beautifyTeamName(teamId);
  }
}

// ============================================================================
// ✅ TAB 2: ПЛЕЙ-ОФ (playoffs/{leagueId}/matches/{matchId})
// ============================================================================
class _PlayoffView extends StatelessWidget {
  const _PlayoffView({
    required this.db,
    required this.selectedLeague,
    required this.leagues,
  });

  final FirebaseFirestore db;
  final String selectedLeague;
  final Map<String, String> leagues;

  @override
  Widget build(BuildContext context) {
    final leagueIds = const ['premier', '1', '2', '3'];
    final showAll = selectedLeague == 'all';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      children: (showAll ? leagueIds : [selectedLeague]).map((leagueId) {
        return _PlayoffLeagueBlock(
          db: db,
          leagueId: leagueId,
          title: leagues[leagueId] ?? leagueId,
        );
      }).toList(),
    );
  }
}

class _PlayoffLeagueBlock extends StatelessWidget {
  const _PlayoffLeagueBlock({
    required this.db,
    required this.leagueId,
    required this.title,
  });

  final FirebaseFirestore db;
  final String leagueId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final col = db.collection('playoffs').doc(leagueId).collection('matches');
    // ✅ Підтягуємо teams (щоб швидко мапити teamId -> name/logo)
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('teams').where('leagueId', isEqualTo: leagueId).snapshots(),
      builder: (context, teamSnap) {
        final teamMap = <String, Map<String, String>>{};
        if (teamSnap.hasData) {
          for (final d in teamSnap.data!.docs) {
            final t = d.data();
            teamMap[d.id] = {
              'name': _beautifyTeamName((t['name'] ?? d.id).toString()),
              'logoUrl': (t['logoUrl'] ?? '').toString(),
            };
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: col.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _GlassBlock(
                title: title,
                child: Text(
                  'Помилка плей-оф: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
                ),
              );
            }
            if (!snap.hasData) {
              return _GlassBlock(
                title: title,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final matches = docs.map((d) {
              final m = d.data();

              String teamName(String? id) {
                final x = (id ?? '').trim();
                if (x.isEmpty) return '—';
                return teamMap[x]?['name'] ?? _beautifyTeamName(x);
              }

              String logoUrl(String? id) {
                final x = (id ?? '').trim();
                if (x.isEmpty) return '';
                return teamMap[x]?['logoUrl'] ?? '';
              }

              final stage = (m['stage'] ?? d.id).toString();
              final order = _toInt(m['order']);
              final legs = _toInt(m['legs']);
              final homeId = (m['homeTeamId'] ?? '').toString();
              final awayId = (m['awayTeamId'] ?? '').toString();

              // 1 матч
              final hs1 = m['homeScore'] == null ? null : _toInt(m['homeScore']);
              final as1 = m['awayScore'] == null ? null : _toInt(m['awayScore']);

              // 2 матч (для SF)
              final hs2 = m['homeScore2'] == null ? null : _toInt(m['homeScore2']);
              final as2 = m['awayScore2'] == null ? null : _toInt(m['awayScore2']);

              final status = (m['status'] ?? '').toString(); // scheduled/live/finished
              final startAt = (m['startAt'] is Timestamp) ? (m['startAt'] as Timestamp).toDate() : null;

              return _PlayoffMatchLite(
                id: d.id,
                stage: stage,
                order: order,
                legs: legs <= 0 ? 1 : legs,
                homeTeamId: homeId,
                awayTeamId: awayId,
                homeName: teamName(homeId),
                awayName: teamName(awayId),
                homeLogo: logoUrl(homeId),
                awayLogo: logoUrl(awayId),
                homeScore1: hs1,
                awayScore1: as1,
                homeScore2: hs2,
                awayScore2: as2,
                status: status,
                startAt: startAt,
              );
            }).toList();

            matches.sort((a, b) {
              final s = _stageRank(a.stage).compareTo(_stageRank(b.stage));
              if (s != 0) return s;
              if (s =='f1') return 99;
              return a.order.compareTo(b.order);
            });

            return _GlassBlock(
              title: '$title • Плей-оф',
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ...matches.map((m) => _PlayoffMatchCard(m: m)).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PlayoffMatchCard extends StatelessWidget {
  const _PlayoffMatchCard({required this.m});
  final _PlayoffMatchLite m;

  @override
  Widget build(BuildContext context) {

    String stageLabel(String s) {
      if (s.startsWith('qf')) return '1/4 фіналу';
      if (s.startsWith('sf')) return '1/2 фіналу';
      if (s.contains('final') || s == 'f') return 'Фінал';
      return '';
    }

    bool hasScore(int? a, int? b) {
      if (a == null || b == null) return false;
      return !(a == 0 && b == 0);
    }

    final showLeg2 = m.legs >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [

          /// СТАДИЯ
          Center(
            child: Text(
              stageLabel(m.stage),
              style: const TextStyle(
                color: Color(0xFFFF8A00),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [

              /// HOME
              Expanded(
                child: Column(
                  children: [
                    _LogoCircle(url: m.homeLogo),
                    const SizedBox(height: 6),
                    Text(
                      m.homeName,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// SCORE
              Column(
                children: [
                  if (hasScore(m.homeScore1, m.awayScore1))
                    Text(
                      '${m.homeScore1}:${m.awayScore1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),

                  if (showLeg2 && hasScore(m.homeScore2, m.awayScore2))
                    Text(
                      '${m.homeScore2}:${m.awayScore2}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 10),

              /// AWAY
              Expanded(
                child: Column(
                  children: [
                    _LogoCircle(url: m.awayLogo),
                    const SizedBox(height: 6),
                    Text(
                      m.awayName,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _PlayoffMatchLite {
  _PlayoffMatchLite({
    required this.id,
    required this.stage,
    required this.order,
    required this.legs,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeScore1,
    required this.awayScore1,
    required this.homeScore2,
    required this.awayScore2,
    required this.status,
    required this.startAt,
  });

  final String id;
  final String stage;
  final int order;
  final int legs;

  final String homeTeamId;
  final String awayTeamId;

  final String homeName;
  final String awayName;

  final String homeLogo;
  final String awayLogo;

  final int? homeScore1;
  final int? awayScore1;

  final int? homeScore2;
  final int? awayScore2;

  final String status;
  final DateTime? startAt;
}

int _stageRank(String s) {
  // qf -> 1, sf -> 2, final -> 3
  if (s.startsWith('qf')) return 1;
  if (s.startsWith('sf')) return 2;
  if (s.contains('final') || s == 'f') return 3;
  return 9;
}

// ============================================================================
// ✅ TAB 3: СТАТИСТИКА (голи/асисти/жк/чк) + фільтр по лігах
// ============================================================================
class _StatsView extends StatelessWidget {
  const _StatsView({
    required this.db,
    required this.selectedLeague,
    required this.leagues,
    required this.tab,
    required this.onTabChanged,
  });

  final FirebaseFirestore db;
  final String selectedLeague;
  final Map<String, String> leagues;

  final _StatsTab tab;
  final ValueChanged<_StatsTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final title = selectedLeague == 'all'
        ? 'Статистика • Усі ліги'
        : 'Статистика • ${leagues[selectedLeague] ?? selectedLeague}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      child: _GlassBlock(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // ✅ 4 кнопки В ОДИН РЯД: Голи / Асисти / ЖК / ЧК
            Row(
              children: [
                Expanded(
                  child: _StatsTabBtn(
                    text: 'Голи',
                    selected: tab == _StatsTab.goals,
                    onTap: () => onTabChanged(_StatsTab.goals),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatsTabBtn(
                    text: 'Асисти',
                    selected: tab == _StatsTab.assists,
                    onTap: () => onTabChanged(_StatsTab.assists),
                  ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatsTabBtn(
                    text: 'ЖК',
                    selected: tab == _StatsTab.yellow,
                    onTap: () => onTabChanged(_StatsTab.yellow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatsTabBtn(
                    text: 'ЧК',
                    selected: tab == _StatsTab.red,
                    onTap: () => onTabChanged(_StatsTab.red),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ Підтягуємо teams -> leagueId (щоб фільтрувати гравців по лігах)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('teams').snapshots(),
              builder: (context, teamsSnap) {
                if (!teamsSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final teamLeague = <String, String>{};
                final teamName = <String, String>{};
                final teamLogo = <String, String>{};

                for (final d in teamsSnap.data!.docs) {
                  final t = d.data();
                  teamLeague[d.id] = (t['leagueId'] ?? '').toString();
                  teamName[d.id] = _beautifyTeamName((t['name'] ?? d.id).toString());
                  teamLogo[d.id] = (t['logoUrl'] ?? '').toString();
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db.collection('players').snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text(
                        'Помилка статистики: ${snap.error}',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
                      );
                    }
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final players = snap.data!.docs.map((d) {
                      final p = d.data();
                      final first = (p['firstName'] ?? '').toString().trim();
                      final last = (p['lastName'] ?? '').toString().trim();
                      final number = (p['number'] ?? '').toString().trim();
                      final tId = (p['teamId'] ?? '').toString().trim();

                      final displayName = ('${last.trim()} ${first.trim()}').trim();
                      final name = displayName.isEmpty ? 'Без імені' : displayName;

                      final goals = _toInt(p['goals']);
                      final assists = _toInt(p['assists']); // якщо поля нема — буде 0
                      final yellow = _toInt(p['yellow']);
                      final red = _toInt(p['red']);

                      return _PlayerStatLite(
                        id: d.id,
                        name: name,
                        number: number,
                        teamId: tId,
                        teamName: teamName[tId] ?? '',
                        teamLogo: teamLogo[tId] ?? '',
                        leagueId: teamLeague[tId] ?? '',
                        goals: goals,
                        assists: assists,
                        yellow: yellow,
                        red: red,
                      );
                    }).toList();
                    // ✅ фільтр по лізі
                    final filtered = (selectedLeague == 'all')
                        ? players.where((p) => const ['premier', '1', '2', '3'].contains(p.leagueId)).toList()
                        : players.where((p) => p.leagueId == selectedLeague).toList();

                    int valueOf(_PlayerStatLite p) {
                      switch (tab) {
                        case _StatsTab.goals:
                          return p.goals;
                        case _StatsTab.assists:
                          return p.assists;
                        case _StatsTab.yellow:
                          return p.yellow;
                        case _StatsTab.red:
                          return p.red;
                      }
                    }

                    filtered.sort((a, b) {
                      final v = valueOf(b).compareTo(valueOf(a));
                      if (v != 0) return v;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

                    final top = filtered.where((p) => valueOf(p) > 0).toList();

                    if (top.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 10),
                        child: Text(
                          'Поки що немає даних статистики (усі значення 0).',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                        ),
                      );
                    }

                    return Column(
                      children: top.take(100).toList().asMap().entries.map((e) {
                        final idx = e.key + 1;
                        final p = e.value;
                        final val = valueOf(p);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.10)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text(
                                  '$idx',
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900),
                                ),
                              ),
                              _LogoCircle(url: p.teamLogo),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _playerDisplayName(p.name, p.number),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$val',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF8A00),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
class _StatsTabBtn extends StatelessWidget {
  const _StatsTabBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFF8A00).withOpacity(0.22) : Colors.black.withOpacity(0.22);
    final border = selected ? const Color(0xFFFF8A00).withOpacity(0.85) : Colors.white.withOpacity(0.10);
    final fg = selected ? const Color(0xFFFF8A00) : Colors.white.withOpacity(0.80);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8A00).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: fg, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PlayerStatLite {
  _PlayerStatLite({
    required this.id,
    required this.name,
    required this.number,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.leagueId,
    required this.goals,
    required this.assists,
    required this.yellow,
    required this.red,
  });

  final String id;
  final String name;
  final String number;

  final String teamId;
  final String teamName;
  final String teamLogo;
  final String leagueId;

  final int goals;
  final int assists;
  final int yellow;
  final int red;
}

String _playerDisplayName(String name, String number) {
  final n = number.trim();
  if (n.isEmpty) return name;
  return '$name • №$n';
}

// ============================================================================
// ✅ HELPERS
// ============================================================================
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

/// ✅ Убираем FK/FC/ФК + fk_ + подчёркивания + делаем нормальный вид
String _beautifyTeamName(String s) {
  var x = s.trim();
  final lower = x.toLowerCase();

  if (lower.startsWith('fk_')) x = x.substring(3);
  if (lower.startsWith('fk ')) x = x.substring(3);
  if (lower.startsWith('fc ')) x = x.substring(3);
  if (lower.startsWith('фк ')) x = x.substring(3);
  if (lower.startsWith('лфк ')) x = x.substring(4);

  x = x.replaceAll('_', ' ').trim();
  x = x.split(' ').where((p) => p.trim().isNotEmpty).join(' ');

  final parts = x.split(' ');
  final fixed = parts.map((p) {
    if (p.isEmpty) return p;
    if (p.contains(RegExp(r'\d'))) return p;
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return fixed.trim().isEmpty ? s : fixed;
}