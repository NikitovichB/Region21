import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlayerCardSheet {
  static Future<void> open(
    BuildContext context, {
    required String playerId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlayerCardSheetBody(playerId: playerId),
    );
  }
}

class _PlayerCardSheetBody extends StatelessWidget {
  const _PlayerCardSheetBody({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final top = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: top + 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E0F12).withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white10),
        ),
        child: SafeArea(
          top: false,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: db.collection('players').doc(playerId).snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return _SheetInner(
                  child: _CenterText('Помилка: ${snap.error}'),
                );
              }
              if (!snap.hasData) {
                return const _SheetInner(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.orange)),
                );
              }
              if (!snap.data!.exists) {
                return const _SheetInner(child: _CenterText('Гравця не знайдено'));
              }

              final p = snap.data!.data()!;
              final first = (p['firstName'] ?? '').toString();
              final last = (p['lastName'] ?? '').toString();
              final number = (p['number'] ?? '').toString();
              final position = (p['position'] ?? '').toString();
              final teamId = (p['teamId'] ?? '').toString();
              final photoUrl = (p['photoUrl'] ?? '').toString();

              // базовая стата (позже можно заменить на seasonStats)
              final goals = _asInt(p['goals']);
              final assists = _asInt(p['assists']);
              final yellow = _asInt(p['yellowCards']);
              final red = _asInt(p['redCards']);

              return _SheetInner(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // “ручка”
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _AvatarBig(url: photoUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${last.isEmpty ? '(без прізвища)' : last} ${first.isEmpty ? '' : first}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                overflow: TextOverflow.ellipsis,

),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(text: number.isEmpty ? '#—' : '#$number'),
                                  _Pill(text: _posLabel(position)),
                                  if (teamId.isNotEmpty) _TeamPill(teamId: teamId),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text('Статистика', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'Голи', value: goals.toString())),
                        const SizedBox(width: 10),
                        Expanded(child: _StatTile(label: 'Асисти', value: assists.toString())),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'Жовті', value: yellow.toString())),
                        const SizedBox(width: 10),
                        Expanded(child: _StatTile(label: 'Червоні', value: red.toString())),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // место под админские кнопки (позже подключим к матчу)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Далі тут зробимо кнопки для адмінки:\nГол • Асист • Жовта • Червона',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SheetInner extends StatelessWidget {
  const _SheetInner({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}

class _AvatarBig extends StatelessWidget {
  const _AvatarBig({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final has = url.trim().isNotEmpty;
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        image: has ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: has ? null : const Icon(Icons.person, size: 34, color: Colors.white70),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

@override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.orange.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.orange.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class _TeamPill extends StatelessWidget {
  const _TeamPill({required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: db.collection('teams').doc(teamId).get(),
      builder: (context, snap) {
        final name = (snap.data?.data()?['name'] ?? teamId).toString();
        return _Pill(text: _beautifyTeamName(name));
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  const _CenterText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

String _posLabel(String pos) {
  switch (pos) {
    case 'GK':
      return 'Воротар';
    case 'DF':
      return 'Захисник';
    case 'MF':
      return 'Півзахисник';
    case 'WG':
      return 'Вінгер';
    case 'FW':
      return 'Нападник';
    default:
      return pos.isEmpty ? '—' : pos;
  }
}

String _beautifyTeamName(String s) {
  var x = s.trim();
  final low = x.toLowerCase();
  if (low.startsWith('fk_')) x = x.substring(3);
  if (low.startsWith('fk ')) x = x.substring(3);
  if (low.startsWith('fc ')) x = x.substring(3);
  if (low.startsWith('фк ')) x = x.substring(3);
  x = x.replaceAll('_', ' ').trim();
  x = x.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
  return x.isEmpty ? '—' : x;
}