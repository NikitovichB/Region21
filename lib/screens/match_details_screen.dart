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

        /// ✅ ФОНОВАЯ КАРТИНКА
        Positioned.fill(
          child: Image.asset(
            'assets/back.jpg',
            fit: BoxFit.cover,
          ),
        ),

        /// ✅ затемнение поверх картинки (чтобы текст читался)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.55),
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
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

              final data = snap.data!.data() ?? {};

              final status = (data['status'] ?? '').toString();
              final leagueId = (data['leagueId'] ?? '').toString();

              final homeId = (data['homeTeamId'] ?? '').toString();
              final awayId = (data['awayTeamId'] ?? '').toString();

              final homeScore = (data['homeScore'] ?? 0).toString();
              final awayScore = (data['awayScore'] ?? 0).toString();

              final startAtTs = data['startAt'];
              DateTime? start;
              if (startAtTs is Timestamp) start = startAtTs.toDate();

              final date = start == null
                  ? '—'
                  : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';

              final fieldLabel = _fieldLabelFromData(data);

              final streamUrl = (data['streamUrl'] ?? '').toString().trim();
              final isLive = status == 'live';
              final isFinished = status == 'finished';

              final centerText =
                  (isLive || isFinished) ? '$homeScore : $awayScore' : '—';

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [

                  /// HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(22),
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

if (isLive) const _LivePill(),
                                if (!isLive)
                                  Text(
                                    isFinished
                                        ? 'Завершено'
                                        : 'Заплановано',
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
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: _TeamLogoName(
        teamId: homeId,
        align: TextAlign.center,
        onTap: () => TeamScreen.open(context, teamId: homeId),
      ),
    ),
    const SizedBox(width: 12),
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        centerText,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: isLive ? Colors.red : Colors.white,
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _TeamLogoName(
        teamId: awayId,
        align: TextAlign.center,
        onTap: () => TeamScreen.open(context, teamId: awayId),
      ),
    ),
  ],
),
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

                        if (streamUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PrimaryButton(
                            text: 'Дивитись онлайн',
                            onTap: () =>
                                _openUrl(context, streamUrl),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (!isLive && !isFinished)
                    const _CenterBox(
                        text: 'Матч ще не розпочався', subtle: true)
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

class _TeamLogoName extends StatelessWidget {
  const _TeamLogoName({
    required this.teamId,
    required this.align,
    required this.onTap,
  });

  final String teamId;
  final TextAlign align;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: db.collection('teams').doc(teamId.toLowerCase()).get(),
              builder: (context, snap) {
                final data = snap.data?.data();
                final logoUrl = (data?['logoUrl'] ?? '').toString().trim();

                return Container(
                  width: 64, // ✅ больше лого
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.25),
                    border: Border.all(color: Colors.white10),
                    image: logoUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: logoUrl.isEmpty
                      ? const Icon(Icons.shield_rounded, size: 30, color: Colors.white70)
                      : null,
                );
              },
            ),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: db.collection('teams').doc(teamId.toLowerCase()).get(),
              builder: (context, snap) {
                final data = snap.data?.data();
                final raw = (data?['name'] ?? teamId).toString();
                final name = _beautifyTeamName(raw);

                return Text(
                  name,
                  textAlign: align,
                  maxLines: 2, // ✅ если длинное — в 2 строки
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

              ...events.map((e) => _TimelineRow(event: e)),
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
    final isHome = event.side == 'home';
    final isAway = event.side == 'away';

    final icon = _eventIcon(event.type);
    final iconColor = _eventColor(event.type);

    final minuteText = event.minute == null ? '' : '${event.minute}′';
    final player = (event.playerName ?? '').trim();
    final assist = (event.assistName ?? '').trim();
    final note = (event.note ?? '').trim();

// ✅ START — по центру: текст + свисток + иконка по центру
if (event.type == 'start') {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        const Text(
          'Матч почався',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const SizedBox(height: 10),
        _CenterIcon(icon: icon, color: iconColor),
      ],
    ),
  );
}

// ✅ END — так же по центру в самом низу
if (event.type == 'end') {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      children: [
        const SizedBox(height: 6),
        const SizedBox(height: 10),
        _CenterIcon(icon: icon, color: iconColor),
        const Text(
          'Матч завершено',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          textAlign: TextAlign.center,
        ),

      ],
    ),
  );
}

    Widget buildSideText({required TextAlign align}) {
      // VAR
      if (event.type == 'var') {
        final title = note.isEmpty ? 'VAR' : 'VAR ($note)';
        final text = minuteText.isEmpty ? title : '$title • $minuteText';
        return Text(
          text,
          textAlign: align,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        );
      }

      // goal / yellow / red — вместо "ГОЛ/Жовта" показываем игрока
      final main = player.isEmpty
          ? _eventTitle(event.type)
          : (minuteText.isEmpty ? player : '$player • $minuteText');

      return Column(
        crossAxisAlignment:
            align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            main,
            textAlign: align,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          if (event.type == 'goal' && assist.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Асист: $assist',
                textAlign: align,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      );
    }

    // neutral (без стороны) — центрируем
    final isNeutral = !isHome && !isAway;

    if (isNeutral) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Text(
              _eventTitleWithNote(event.type, note),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (minuteText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                minuteText,
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 10),
            _CenterIcon(icon: icon, color: iconColor),
          ],
        ),
      );
    }

    // обычные события — текст возле центра (как ты хотел)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT (home) — справа к центру
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: isHome ? buildSideText(align: TextAlign.right) : const SizedBox.shrink(),
              ),
            ),
          ),
          // CENTER
          _CenterIcon(icon: icon, color: iconColor),

          // RIGHT (away) — слева к центру
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: isAway ? buildSideText(align: TextAlign.left) : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterIcon extends StatelessWidget {
  const _CenterIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Container(width: 2, height: 10, color: Colors.white10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Container(width: 2, height: 10, color: Colors.white10),
        ],
      ),
    );
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
      return Icons.videocam_outlined;
    case 'start':
      return Icons.sports; // иконка центра (сам старт мы рисуем свистком выше)
    case 'end':
      return Icons.sports;
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
    default:
      return Colors.white70;
  }
}

String _eventTitle(String type) {
  switch (type) {
    case 'goal':
      return 'Гол';
    case 'yellow':
      return 'Жовта картка';
    case 'red':
      return 'Червона картка';
    case 'var':
      return 'VAR';
    case 'start':
      return 'Матч почався';
    case 'end':
      return 'Матч завершено';
    default:
      return type.isEmpty ? 'Подія' : type;
  }
}

String _eventTitleWithNote(String type, String note) {
  final base = _eventTitle(type);
  final n = note.trim();
  if (type == 'var' && n.isNotEmpty) return '$base ($n)';
  return base;
}

// ===== event model =====

class _MatchEvent {
  final String id;
  final String type; // start/goal/yellow/red/var/end
  final String? side; // home/away/null
  final int? minute;
  final String? playerName;
  final String? assistName;
  final String? note;

  _MatchEvent({
    required this.id,
    required this.type,
    required this.side,
    required this.minute,
    required this.playerName,
    required this.assistName,
    required this.note,
  });

  factory _MatchEvent.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final type = (data['type'] ?? '').toString().trim();
    final side = (data['side'] ?? '').toString().trim(); // ✅ ВАЖНО: side

    final minuteRaw = data['minute'];
    int? minute;
    if (minuteRaw is num) minute = minuteRaw.toInt();

    final playerName = (data['playerName'] ?? '').toString().trim();
    final assistName = (data['assistName'] ?? '').toString().trim();
    final note = (data['note'] ?? '').toString().trim();

    return _MatchEvent(
      id: doc.id,
      type: type.isEmpty ? 'event' : type,
      side: side.isEmpty ? null : side,
      minute: minute,
      playerName: playerName.isEmpty ? null : playerName,
      assistName: assistName.isEmpty ? null : assistName,
      note: note.isEmpty ? null : note,
    );
  }
}

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
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
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
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: db.collection('teams').doc(teamId.toLowerCase()).get(),
                  builder: (context, snap) {
                    final data = snap.data?.data();
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

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: db.collection('teams').doc(id.toLowerCase()).get(),
      builder: (context, snap) {
        final logoUrl = snap.data?.data()?['logoUrl']?.toString() ?? '';

        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white10),
            image: logoUrl.trim().isNotEmpty
                ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                : null,
          ),
          child: logoUrl.trim().isEmpty
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
  if (low.startsWith('лфк ')) x = x.substring(4);

  x = x.replaceAll('_', ' ').trim();

  final parts = x.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
  if (parts.isEmpty) return '—';

  x = parts.map((p) {
    if (p.isEmpty) return p;
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ');

  return x;
}