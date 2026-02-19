import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'team_screen.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final _db = FirebaseFirestore.instance;

  static const Map<String, String> _leagues = {
    'all': 'Усі ліги',
    'premier': 'Премʼєр-ліга',
    '1': 'Перша ліга',
    '2': 'Друга ліга',
    '3': 'Третя ліга',
  };

  String selectedLeague = 'all';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _LeagueDropdown(
                  value: selectedLeague,
                  onChanged: (v) => setState(() => selectedLeague = v),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('teams').snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Помилка таблиці:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teams = snap.data!.docs.map((d) {
                      final data = d.data();
                      final rawName = (data['name'] ?? d.id).toString();
                      return _TeamLite(
                        id: d.id,
                        name: _beautifyTeamName(rawName),
                        leagueId: (data['leagueId'] ?? '').toString(),
                        logoUrl: (data['logoUrl'] ?? '').toString(),
                      );
                    }).toList();

                    final byLeague = <String, List<_TeamLite>>{
                      'premier': [],
                      '1': [],
                      '2': [],
                      '3': [],
                    };

                    for (final t in teams) {
                      if (byLeague.containsKey(t.leagueId)) {
                        byLeague[t.leagueId]!.add(t);
                      }
                    }

                    for (final k in byLeague.keys) {
                      byLeague[k]!.sort(
                        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                      );
                    }

                    final hasAny = byLeague.values.any((l) => l.isNotEmpty);
                    if (!hasAny) {
                      return const Center(
                        child: Text(
                          'Команд поки що немає.\nДодай команди в адмінці.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }

                    final showAll = selectedLeague == 'all';

                    final blocks = <Widget>[];
                    if (showAll) {
                      blocks.addAll(_buildLeagueBlocks(byLeague));
                    } else {
                      final key = selectedLeague;
                      blocks.add(
                        _LeagueBlock(
                          leagueTitle: _leagues[key] ?? key,
                          teams: byLeague[key] ?? const [],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                      children: blocks,
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

  List<Widget> _buildLeagueBlocks(Map<String, List<_TeamLite>> byLeague) {
    final result = <Widget>[];
    const order = ['premier', '1', '2', '3'];

    for (final leagueId in order) {
      final list = byLeague[leagueId] ?? const [];
      if (list.isEmpty) continue;

      result.add(
        _LeagueBlock(
          leagueTitle: _leagues[leagueId] ?? leagueId,
          teams: list,
        ),
      );
    }

    return result;
  }
}

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

class _LeagueBlock extends StatelessWidget {
  const _LeagueBlock({required this.leagueTitle, required this.teams});

  final String leagueTitle;
  final List<_TeamLite> teams;

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
            leagueTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF8A00),
            ),
          ),
          const SizedBox(height: 10),
          const _TableHeader(),
          const SizedBox(height: 8),
          ...teams.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final team = entry.value;

            return _TeamRow(
              index: index,
              teamId: team.id, // ✅ важно для клика
              teamName: team.name,
              logoUrl: team.logoUrl,
              played: 0,
              wins: 0,
              draws: 0,
              losses: 0,
              goalsFor: 0,
              goalsAgainst: 0,
              points: 0,
            );
          }),
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
  final String teamId; // ✅
  final String teamName;
  final String logoUrl;

  final int played, wins, draws, losses, goalsFor, goalsAgainst, points;

  @override
  Widget build(BuildContext context) {
    // final gd = goalsFor - goalsAgainst; // пока не используешь

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

          // ✅ Клуб кликабельный (и лого, и текст)
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
      width: 26,
      height: 26,
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

class _TeamLite {
  final String id;
  final String name;
  final String leagueId;
  final String logoUrl;

  _TeamLite({
    required this.id,
    required this.name,
    required this.leagueId,
    required this.logoUrl,
  });
}

/// ✅ Убираем FK/FC/ФК + fk_ + подчёркивания + делаем нормальный вид
String _beautifyTeamName(String s) {
  var x = s.trim();

  // частые префиксы
  final lower = x.toLowerCase();
  if (lower.startsWith('fk_')) x = x.substring(3);
  if (lower.startsWith('fk ')) x = x.substring(3);
  if (lower.startsWith('fc ')) x = x.substring(3);
  if (lower.startsWith('фк ')) x = x.substring(3);
  if (lower.startsWith('лфк ')) x = x.substring(4); // ✅ исправил регистр + длину

  x = x.replaceAll('_', ' ').trim();

  // приводим пробелы в порядок
  x = x.split(' ').where((p) => p.trim().isNotEmpty).join(' ');

  // капитализация (не трогаем слова с цифрами)
  final parts = x.split(' ');
  final fixed = parts.map((p) {
    if (p.isEmpty) return p;
    if (p.contains(RegExp(r'\d'))) return p; // типа 2018
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return fixed.trim().isEmpty ? s : fixed;
}
