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

              final start = (data['startAt'] as Timestamp).toDate();
              final time =
                  '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
              final date =
                  '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';

              final fieldLabel = _fieldLabelFromData(data);

              final streamUrl = (data['streamUrl'] ?? '').toString().trim();
              final isLive = status == 'live';
              final isFinished = status == 'finished';

              final centerText = (isLive || isFinished) ? '$homeScore : $awayScore' : time;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
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

                        // ✅ поле под счетом/временем
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (!isLive && !isFinished)
                    const _CenterBox(text: 'Матч ще не розпочався', subtle: true),

                  if (isFinished)
                    const _CenterBox(text: 'Матч завершено', subtle: true),

                  if (isLive) ...[
                    const _CenterBox(
                      text: 'LIVE-центр (скоро додамо події: голи, картки, заміни)',
                      subtle: true,
                    ),
                    const SizedBox(height: 10),
                    if (streamUrl.isNotEmpty)
                      _PrimaryButton(
                        text: 'Дивитись онлайн',
                        onTap: () => _openUrl(context, streamUrl),
                      ),
                    if (streamUrl.isEmpty)
                      const _CenterBox(
                        text: 'Посилання на трансляцію ще не додано',
                        subtle: true,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
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
        final logoUrl =
            (snap.data?.data() as Map<String, dynamic>?)?['logoUrl']?.toString();

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
