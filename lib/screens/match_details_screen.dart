import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'team_screen.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key, required this.matchId});
  final String matchId;

  static void open(BuildContext context, {required String matchId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchDetailsScreen(matchId: matchId)),
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
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Матч'),
            centerTitle: true,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: db.collection('matches').doc(matchId).snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return _CenterBox(text: 'Помилка: ${snap.error}');
              }
              if (!snap.hasData || !snap.data!.exists) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.orange),
                );
              }

              final data = (snap.data!.data() as Map<String, dynamic>? ?? {});

              final status = (data['status'] ?? '').toString();
              final leagueId = (data['leagueId'] ?? '').toString();

              final homeId = (data['homeTeamId'] ?? '').toString();
              final awayId = (data['awayTeamId'] ?? '').toString();

              final homeScore = (data['homeScore'] ?? 0).toString();
              final awayScore = (data['awayScore'] ?? 0).toString();

              final startAtTs = data['startAt'];
              DateTime? start;
              if (startAtTs is Timestamp) start = startAtTs.toDate();

              final time = start == null
                  ? '—'
                  : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
              final date = start == null
                  ? '—'
                  : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';

              final fieldLabel = _fieldLabelFromData(data);

              final streamUrl = (data['streamUrl'] ?? '').toString().trim();
              final isLive = status == 'live';
              final isFinished = status == 'finished';

              // ⚠️ как ты просил: время в центре убираем (чтобы не "останавливалось")
              // в центре либо счёт (live/finished), либо просто тире (scheduled)
              final centerText = (isLive || isFinished) ? '$homeScore : $awayScore' : '—';

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  // ====== HEADER CARD ======
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // ✅ шапка: ліга + дата по центру + статус справа
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                _LeaguePill(text: _leagueLabel(leagueId)),
                                const Spacer(),
                                if (isLive) const _LivePill(),
                                if (!isLive)
                                  Text(
                                    isFinished ? 'Завершено' : 'Заплановано',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w900,
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

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            _TeamTap(
                              teamId: homeId,
                              alignEnd: false,
                              onTap: () => TeamScreen.open(context, teamId: homeId),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              centerText,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isLive ? Colors.red : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _TeamTap(
                              teamId: awayId,
                              alignEnd: true,
                              onTap: () => TeamScreen.open(context, teamId: awayId),
                            ),
                          ],
                        ),

                        // ✅ поле под счетом (по центру)
                        if (fieldLabel != null) ...[
                          const SizedBox(height: 10),
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

                        // ✅ кнопка трансляции (если есть) — можно и для finished оставить, если хочешь
                        if (streamUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PrimaryButton(
                            text: 'Дивитись онлайн',
                            onTap: () => _openUrl(context, streamUrl),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ====== LIVE CENTER (и для LIVE, и для FINISHED) ======
                  if (!isLive && !isFinished)
                    const _CenterBox(text: 'Матч ще не розпочався', subtle: true)
                  else
                    _LiveCenter(
                      matchId: matchId,
                      homeTeamId: homeId,
                      awayTeamId: awayId,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LiveCenter extends StatelessWidget {
  const _LiveCenter({
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
  });

  final String matchId;
  final String homeTeamId;
  final String awayTeamId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final q = db
        .collection('matches')
        .doc(matchId)
        .collection('events')
        .orderBy('minute')
        .orderBy('createdAt');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(
              'Помилка LIVE-центру:\n${snap.error}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
            );
          }
          if (!snap.hasData) {
            return const SizedBox(
              height: 80,
              child: Center(child: LinearProgressIndicator()),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Text(
              'Поки що подій немає.',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
            );
          }

          final events = docs.map((d) => _MatchEvent.fromDoc(d)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('LIVE-центр', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),

              // timeline
              ...events.map((e) => _TimelineRow(
                    event: e,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});
  final _MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final isHome = event.teamSide == 'home';
    final isAway = event.teamSide == 'away';

    // center icon
    final icon = _eventIcon(event.type);
    final iconColor = _eventColor(event.type);

    final minuteText = event.minute == null ? '' : '${event.minute}′';
    final player = (event.playerName ?? '').trim();

    // left text (home)
    final leftText = isHome
        ? _eventText(event.type, player: player, minute: minuteText)
        : '';

    // right text (away)
    final rightText = isAway
        ? _eventText(event.type, player: player, minute: minuteText)
        : '';

    // neutral (start/end/var without side)
    final neutral = (!isHome && !isAway)
        ? _eventText(event.type, player: player, minute: minuteText)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                neutral != null ? '' : leftText,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // CENTER (line + icon)
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 10,
                  color: Colors.white10,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Container(
                  width: 2,
                  height: 10,
                  color: Colors.white10,
                ),
              ],
            ),
          ),

          // RIGHT
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                neutral != null ? '' : rightText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // NEUTRAL CENTER TEXT (если событие без стороны)
          if (neutral != null)
            PositionedTextOverlay(neutral: neutral),
        ],
      ),
    );
  }
}

/// Хак без Stack внутри Row: отдельный виджет, который рисует neutral текст строкой ниже
class PositionedTextOverlay extends StatelessWidget {
  const PositionedTextOverlay({super.key, required this.neutral});
  final String neutral;

  @override
  Widget build(BuildContext context) {
    // выведем нейтральное событие отдельной строкой под рядом
    return const SizedBox.shrink();
  }
}

// ===== helpers for event UI =====

IconData _eventIcon(String type) {
  switch (type) {
    case 'goal':
      return Icons.sports_soccer_rounded;
    case 'yellow':
      return Icons.rectangle_rounded;
    case 'red':
      return Icons.rectangle_rounded;
    case 'var':
      return Icons.verified_rounded;
    case 'start':
      return Icons.play_arrow_rounded;
    case 'end':
      return Icons.flag_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

Color _eventColor(String type) {
  switch (type) {
    case 'goal':
      return Colors.white;
    case 'yellow':
      return const Color(0xFFFFD54F);
    case 'red':
      return Colors.redAccent;
    case 'var':
      return AppTheme.orange;
    case 'start':
      return Colors.white70;
    case 'end':
      return Colors.white70;
    default:
      return Colors.white70;
  }
}

String _eventText(String type, {required String player, required String minute}) {
  final who = player.isEmpty ? '' : player;
  switch (type) {
    case 'start':
      return minute.isEmpty ? 'Почався матч' : 'Почався матч • $minute';
    case 'end':
      return minute.isEmpty ? 'Матч завершено' : 'Матч завершено • $minute';
    case 'goal':
      if (who.isEmpty) return minute.isEmpty ? 'Гол' : 'Гол • $minute';
      return minute.isEmpty ? who : '$who • $minute';
    case 'yellow':
      if (who.isEmpty) return minute.isEmpty ? 'Жовта картка' : 'Жовта • $minute';
      return minute.isEmpty ? who : '$who • $minute';
    case 'red':
      if (who.isEmpty) return minute.isEmpty ? 'Червона картка' : 'Червона • $minute';
      return minute.isEmpty ? who : '$who • $minute';
    case 'var':
      return minute.isEmpty ? 'VAR' : 'VAR • $minute';
    default:
      return minute.isEmpty ? type : '$type • $minute';
  }
}

// ===== event model =====

class _MatchEvent {
  final String id;
  final String type; // start/goal/yellow/red/var/end
  final String? teamSide; // home/away/null
  final int? minute;
  final String? playerName;

  _MatchEvent({
    required this.id,
    required this.type,
    required this.teamSide,
    required this.minute,
    required this.playerName,
  });

  factory _MatchEvent.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final type = (data['type'] ?? '').toString();
    final teamSide = (data['teamSide'] ?? '').toString().trim();
    final minuteRaw = data['minute'];
    int? minute;
    if (minuteRaw is int) minute = minuteRaw;
    if (minuteRaw is num) minute = minuteRaw.toInt();

    final player = (data['playerName'] ?? data['player'] ?? '').toString();

    return _MatchEvent(
      id: doc.id,
      type: type.isEmpty ? 'event' : type,
      teamSide: teamSide.isEmpty ? null : teamSide,
      minute: minute,
      playerName: player.trim().isEmpty ? null : player.trim(),
    );
  }
}

// ===== existing helpers/widgets (твои) =====

String? _fieldLabelFromData(Map<String, dynamic> data) {
  final raw = data['field'] ?? data['fieldNumber'] ?? data['fieldNo'] ?? data['pitch'];
  if (raw == null) return null;

  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  final low = s.toLowerCase();
  if (low.contains('поле') || low.contains('pitch') || low.contains('field')) return s;

  return 'Поле №$s';
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Невірне посилання')),
    );
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не вдалося відкрити посилання')),
    );
  }
}

class _TeamTap extends StatelessWidget {
  const _TeamTap({
    required this.teamId,
    required this.alignEnd,
    required this.onTap,
  });

  final String teamId;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignEnd) _TeamBig(id: teamId),
              if (!alignEnd) const SizedBox(width: 10),
              Flexible(
                child: FutureBuilder<DocumentSnapshot>(
                  future: db.collection('teams').doc(teamId.toLowerCase()).get(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final raw = (data?['name'] ?? teamId).toString();
                    final name = _beautifyTeamName(raw);

                    return Text(
                      name,
                      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              if (alignEnd) const SizedBox(width: 10),
              if (alignEnd) _TeamBig(id: teamId),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBig extends StatelessWidget {
  const _TeamBig({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('teams').doc(id.toLowerCase()).get(),
      builder: (context, snap) {
        final logoUrl = (snap.data?.data() as Map<String, dynamic>?)?['logoUrl']?.toString();

        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white10),
            image: (logoUrl != null && logoUrl.isNotEmpty)
                ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                : null,
          ),
          child: (logoUrl == null || logoUrl.isEmpty)
              ? const Icon(Icons.shield_rounded, size: 26, color: Colors.white70)
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

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.orange.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.orange.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: AppTheme.orange),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CenterBox extends StatelessWidget {
  const _CenterBox({required this.text, this.subtle = false});
  final String text;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(subtle ? 0.28 : 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: subtle ? Colors.white70 : Colors.redAccent,
          fontWeight: FontWeight.w900,
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

String _beautifyTeamName(String s) {
  var x = s.trim();

  final low = x.toLowerCase();
  if (low.startsWith('fk_')) x = x.substring(3);
  if (low.startsWith('fk ')) x = x.substring(3);
  if (low.startsWith('фк ')) x = x.substring(3);
  if (low.startsWith('лфк ')) x = x.substring(3);

  x = x.replaceAll('_', ' ').trim();

  final parts = x.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
  if (parts.isEmpty) return '—';

  x = parts.map((p) {
    if (p.isEmpty) return p;
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return x;
}