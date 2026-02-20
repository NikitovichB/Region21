
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'match_details_screen.dart';
import 'player_card.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key, required this.teamId});

  final String teamId;

  static void open(BuildContext context, {required String teamId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TeamScreen(teamId: teamId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

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
        DefaultTabController(
          length: 4,
          initialIndex: 0,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text('Команда'),
            ),
            body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: db.collection('teams').doc(teamId).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _CenterBox(text: 'Помилка: ${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.orange),
                  );
                }
                if (!snap.data!.exists) {
                  return const _CenterBox(text: 'Команду не знайдено');
                }

                final data = snap.data!.data()!;
                final rawName = (data['name'] ?? teamId).toString();
                final name = _beautifyTeamName(rawName);
                final logoUrl = (data['logoUrl'] ?? '').toString();
                final leagueId = (data['leagueId'] ?? '').toString();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            _LogoBig(url: logoUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  _LeaguePill(text: _leagueLabel(leagueId)),
                                ],
                              ),
                            ),
                          ],

),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: AppTheme.orange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.orange.withOpacity(0.45),
                            ),
                          ),
                          labelColor: AppTheme.orange,
                          unselectedLabelColor: Colors.white,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                          tabs: const [
                            Tab(text: 'Склад'),
                            Tab(text: 'Матчі'),
                            Tab(text: 'Таблиця'),
                            Tab(text: 'Медіа'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TabSquad(teamId: teamId),
                          _TabMatches(teamId: teamId),
                          _TabTable(teamId: teamId, leagueId: leagueId),
                          const _TabMedia(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================
   TAB: СКЛАД + ПРОГРЕС (5 ігор)
   ========================= */

class _TabSquad extends StatelessWidget {
  const _TabSquad({required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Прогрес', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _finishedMatchesQuery(db, teamId).snapshots(),
                builder: (context, ms) {
                  if (ms.hasError) {
                    return Text(
                      'Помилка: ${ms.error}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  }
                  if (!ms.hasData) {
                    return const SizedBox(
                      height: 44,
                      child: Center(child: LinearProgressIndicator()),
                    );
                  }

                  final docs = ms.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      'Поки що немає завершених матчів.',
                      style: TextStyle(color: Colors.white70),
                    );
                  }

return LayoutBuilder(
                    builder: (context, c) {
                      const gap = 8.0;
                      final count = docs.length.clamp(1, 5);
                      final width = (c.maxWidth - gap * (count - 1)) / count;

                      return Row(
                        children: [
                          for (int i = 0; i < count; i++) ...[
                            if (i != 0) const SizedBox(width: gap),
                            SizedBox(
                              width: width,
                              child: _ProgressChipCompact(
                                match: docs[i],
                                teamId: teamId,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Склад', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db
                    .collection('players')
                    .where('teamId', isEqualTo: teamId)
                    .orderBy('lastName')
                    .orderBy('firstName')
                    .snapshots(),
                builder: (context, ps) {
                  if (ps.hasError) {
                    return Text(
                      'Помилка: ${ps.error}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  }
                  if (!ps.hasData) {
                    return const SizedBox(
                      height: 44,
                      child: Center(child: LinearProgressIndicator()),
                    );
                  }

                  final docs = ps.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      'Поки що гравців немає.',
                      style: TextStyle(color: Colors.white70),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final p = d.data();
                      final first = (p['firstName'] ?? '').toString();
                      final last = (p['lastName'] ?? '').toString();
                      final number = (p['number'] ?? '').toString();
                      final photoUrl = (p['photoUrl'] ?? '').toString();
                      final position = (p['position'] ?? '').toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        // ✅ ВОТ ТУТ НАЖАТИЕ НА ИГРОКА → ОТКРЫВАЕТ КАРТОЧКУ
                        onTap: () => PlayerCardSheet.open(context, playerId: d.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              _PlayerAvatar(url: photoUrl),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

children: [
                                    Text(
                                      '${last.isEmpty ? '(без прізвища)' : last} ${first.isEmpty ? '' : first}',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _posLabel(position),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                number.isEmpty ? '—' : '#$number',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
/* =========================
   TAB: МАТЧІ
   ========================= */

class _TabMatches extends StatelessWidget {
  const _TabMatches({required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _allTeamMatchesQuery(db, teamId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _CenterBox(text: 'Помилка матчів:\n${snap.error}');
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.orange),
          );
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const _CenterBox(text: 'Поки що матчів немає');
        }

        final upcoming = docs.where((d) {
          final s = (d.data()['status'] ?? '').toString();
          // ✅ ВАЖНО: тут ДОЛЖНО БЫТЬ || (иначе всё краснеет)
          return s == 'scheduled' || s == 'live';
        }).toList();

        final finished = docs.where((d) {
          final s = (d.data()['status'] ?? '').toString();
          return s == 'finished';
        }).toList();

        upcoming.sort((a, b) {
          final aTime = (a.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(2100);
          final bTime = (b.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(2100);
          final as = (a.data()['status'] ?? '').toString();
          final bs = (b.data()['status'] ?? '').toString();
          if (as == 'live' && bs != 'live') return -1;
          if (bs == 'live' && as != 'live') return 1;
          return aTime.compareTo(bTime);
        });

        finished.sort((a, b) {
          final aTime = (a.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
          final bTime = (b.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
          return bTime.compareTo(aTime);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 6),
              const _SectionTitle('Майбутні / LIVE'),
              const SizedBox(height: 8),
              ...upcoming.map((m) => _TeamMatchCard(doc: m)).toList(),
              const SizedBox(height: 10),
            ],
            if (finished.isNotEmpty) ...[
              const _SectionTitle('Завершені'),
              const SizedBox(height: 8),
              ...finished.map((m) => _TeamMatchCard(doc: m)).toList(),
            ],
          ],
        );
      },
    );
  }
}

class _TeamMatchCard extends StatelessWidget {
  const _TeamMatchCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();

    final status = (data['status'] ?? '').toString();
    final homeId = (data['homeTeamId'] ?? '').toString();
    final awayId = (data['awayTeamId'] ?? '').toString();
    final leagueId = (data['leagueId'] ?? '').toString();

    final homeScore = (data['homeScore'] ?? 0);
    final awayScore = (data['awayScore'] ?? 0);

    final start = (data['startAt'] as Timestamp?)?.toDate();
    final time = start == null
        ? '—'
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final date = start == null
        ? '—'
        : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';

    final fieldLabel = _fieldLabelFromMap(data);

    final isLive = status == 'live';
    final isFinished = status == 'finished';
    // ✅ ВАЖНО: тут ДОЛЖНО БЫТЬ || (иначе всё краснеет)
    final centerText = (isLive || isFinished) ? '$homeScore : $awayScore' : time;


return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => MatchDetailsScreen.open(context, matchId: doc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
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
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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
            if (fieldLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                fieldLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================
   TAB: ТАБЛИЦЯ
   ========================= */

class _TabTable extends StatelessWidget {
  const _TabTable({required this.teamId, required this.leagueId});
  final String teamId;
  final String leagueId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    if (leagueId.trim().isEmpty) {
      return const _CenterBox(text: 'У команди не вказана ліга (leagueId)');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('teams').where('leagueId', isEqualTo: leagueId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return _CenterBox(text: 'Помилка таблиці:\n${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.orange));
        }

        final teams = snap.data!.docs.map((d) {
          final data = d.data();
          final name = _beautifyTeamName((data['name'] ?? d.id).toString());
          final logoUrl = (data['logoUrl'] ?? '').toString();
          return _TeamLite(id: d.id, name: name, logoUrl: logoUrl);
        }).toList();

        teams.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final idx = teams.indexWhere((t) => t.id == teamId);
        final pos = idx >= 0 ? (idx + 1) : null;

return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Таблиця • ${_leagueLabel(leagueId)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pos == null ? 'Позиція: —' : 'Позиція: #$pos із ${teams.length}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const _MiniTableHeader(),
                  const SizedBox(height: 8),
                  ...teams.asMap().entries.map((e) {
                    final i = e.key + 1;
                    final t = e.value;
                    final isMe = t.id == teamId;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$i',
                              style: TextStyle(
                                color: isMe ? AppTheme.orange : Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _LogoCircle(url: t.logoUrl, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe ? AppTheme.orange : Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 22,
                            child: Text('0',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(
                            width: 22,
                            child: Text('0',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(
                            width: 22,
                            child: Text('0',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(
                            width: 22,
                            child: Text('0',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),

),
                          const SizedBox(
                            width: 46,
                            child: Text('0:0',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                )),
                          ),
                          const SizedBox(
                            width: 26,
                            child: Text('0',
                                textAlign: TextAlign.end,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniTableHeader extends StatelessWidget {
  const _MiniTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontWeight: FontWeight.w900,
      color: Colors.white70,
      fontSize: 12,
    );

    return const Row(
      children: [
        SizedBox(width: 24, child: Text('#', style: style)),
        SizedBox(width: 24, height: 24),
        SizedBox(width: 8),
        Expanded(child: Text('Клуб', style: style)),
        SizedBox(width: 22, child: Text('І', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 22, child: Text('В', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 22, child: Text('Н', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 22, child: Text('П', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 46, child: Text('Г', textAlign: TextAlign.center, style: style)),
        SizedBox(width: 26, child: Text('О', textAlign: TextAlign.end, style: style)),
      ],
    );
  }
}

class _TabMedia extends StatelessWidget {
  const _TabMedia();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _CenterBox(text: 'Медіа скоро додамо ✅'),
    );
  }
}
/* =========================
   PROGRESS CHIP (compact)
   ========================= */

class _ProgressChipCompact extends StatelessWidget {
  const _ProgressChipCompact({required this.match, required this.teamId});

  final QueryDocumentSnapshot<Map<String, dynamic>> match;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final data = match.data();

    final homeId = (data['homeTeamId'] ?? '').toString();
    final awayId = (data['awayTeamId'] ?? '').toString();
    final homeScore = (data['homeScore'] ?? 0) as num;
    final awayScore = (data['awayScore'] ?? 0) as num;

    final start = (data['startAt'] as Timestamp?)?.toDate();
    final date = start == null
        ? '—'
        : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';

    final isHome = homeId == teamId;
    final my = isHome ? homeScore : awayScore;
    final opp = isHome ? awayScore : homeScore;

    String res;
    if (my > opp) {
      res = 'W';
    } else if (my == opp) {
      res = 'D';
    } else {
      res = 'L';
    }

    final opponentId = isHome ? awayId : homeId;
    final color = _resultColor(res);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => MatchDetailsScreen.open(context, matchId: match.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            _TeamMini(teamId: opponentId, size: 22),
            const SizedBox(height: 6),
            Text(
              '${homeScore.toInt()}:${awayScore.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withOpacity(0.65)),
              ),
              child: Text(
                res,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _resultColor(String res) {
  if (res == 'W') return Colors.greenAccent;
  if (res == 'D') return Colors.white38;
  return Colors.redAccent;
}

/* =========================
   QUERIES
   ========================= */

Query<Map<String, dynamic>> _allTeamMatchesQuery(FirebaseFirestore db, String teamId) {
  return db.collection('matches').where(
        Filter.or(
          Filter('homeTeamId', isEqualTo: teamId),
          Filter('awayTeamId', isEqualTo: teamId),
        ),
      );
}

Query<Map<String, dynamic>> _finishedMatchesQuery(FirebaseFirestore db, String teamId) {
  return _allTeamMatchesQuery(db, teamId)
      .where('status', isEqualTo: 'finished')
      .orderBy('startAt', descending: true)
      .limit(5);
}

/* =========================
   SMALL WIDGETS
   ========================= */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

@override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Colors.white70,
      ),
    );
  }
}

class _LogoBig extends StatelessWidget {
  const _LogoBig({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        image: has ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: has ? null : const Icon(Icons.shield_rounded, size: 30, color: Colors.white70),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.url, this.size = 26});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        image: hasUrl ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: hasUrl ? null : Icon(Icons.shield_rounded, size: size * 0.58, color: Colors.white70),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        image: has ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: has ? null : const Icon(Icons.person, size: 18, color: Colors.white70),
    );
  }
}

class _CenterBox extends StatelessWidget {
  const _CenterBox({required this.text});
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
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
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

class _TeamName extends StatelessWidget {
  const _TeamName({required this.teamId, required this.alignEnd});
  final String teamId;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: db.collection('teams').doc(teamId).get(),
      builder: (context, snap) {
        final data = snap.data?.data();
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
  const _TeamMini({required this.teamId, this.size = 34});
  final String teamId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: db.collection('teams').doc(teamId).get(),
      builder: (context, snap) {
        final logoUrl = snap.data?.data()?['logoUrl']?.toString() ?? '';
        return _LogoCircle(url: logoUrl, size: size);
      },
    );
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
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
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   MODELS + HELPERS
   ========================= */

class _TeamLite {
  final String id;
  final String name;
  final String logoUrl;

  _TeamLite({required this.id, required this.name, required this.logoUrl});
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

String? _fieldLabelFromMap(Map<String, dynamic> data) {
  final raw = data['field'] ?? data['fieldNumber'] ?? data['pitch'] ?? data['fieldNo'];
  if (raw == null) return null;

  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  final low = s.toLowerCase();
  // ✅ ВАЖНО: тут ДОЛЖНО БЫТЬ || (иначе всё краснеет)
 if (low.contains('поле') ||
     low.contains('pitch') ||
     low.contains('field')) return s;
  return 'Поле №$s';
}

/// Убираем FK/FC/ФК + fk_ + подчёркивания
String _beautifyTeamName(String s) {
  var x = s.trim();

  final lower = x.toLowerCase();
  if (lower.startsWith('fk_')) x = x.substring(3);
  if (lower.startsWith('fk ')) x = x.substring(3);
  if (lower.startsWith('fc ')) x = x.substring(3);
  if (lower.startsWith('фк ')) x = x.substring(3);

  x = x.replaceAll('_', ' ').trim();
  x = x.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');

  final hasUpper = RegExp(r'[A-ZА-ЯІЇЄҐ]').hasMatch(x);
  if (hasUpper) return x;

  final parts = x.split(' ');
  final fixed = parts.map((p) {
    if (p.isEmpty) return p;
    if (p.contains(RegExp(r'\d'))) return p;
    if (p.length == 1) return p.toUpperCase();
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return fixed.trim().isEmpty ? s : fixed;
}

String _posLabel(String pos) {
  switch (pos) {
    case 'GK':
      return 'Воротар (GK)';
    case 'DF':
      return 'Захисник (DF)';
    case 'MF':
      return 'Півзахисник (MF)';
    case 'WG':
      return 'Вінгер (WG)';
    case 'FW':
      return 'Нападник (FW)';
    default:
      return pos.isEmpty ? '—' : pos;
  }
}