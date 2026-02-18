import 'package:flutter/material.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final List<String> leagues = [
    'Усі ліги',
    'Прем\'єр-ліга',
    'Перша ліга',
    'Друга ліга',
    'Третя ліга',
    'Четверта ліга',
    'П\'ята ліга',
  ];

  String selectedLeague = 'Усі ліги';

  final Map<String, List<TeamStats>> standings = {
    'Прем\'єр-ліга': [
      TeamStats('OnlyAks', 5, 4, 1, 0, 29, 12),
      TeamStats('Spartans', 5, 4, 1, 0, 24, 12),
      TeamStats('Гаси', 6, 3, 0, 3, 19, 18),
      TeamStats('FC Provocator bar', 5, 3, 0, 2, 19, 15),
      TeamStats('LunaPharma 2018', 6, 2, 2, 2, 22, 19),
      TeamStats('Kentasy', 5, 2, 1, 2, 12, 9),
      TeamStats('Армагеддон', 6, 1, 3, 2, 12, 17),
      TeamStats('Градорембуд', 6, 1, 1, 4, 13, 29),
      TeamStats('Urban', 6, 0, 1, 5, 13, 32),
    ],
    'Перша ліга': List.generate(8, (i) => TeamStats('Ліга1 ${i + 1}', 10, 6 - i, i, i % 3, 18 - i, 10 + i)),
    'Друга ліга': List.generate(8, (i) => TeamStats('Ліга2 ${i + 1}', 10, 5 - i, i, i % 4, 16 - i, 9 + i)),
    'Третя ліга': List.generate(8, (i) => TeamStats('Ліга3 ${i + 1}', 10, 4 - i, i, i % 2, 14 - i, 11 + i)),
    'Четверта ліга': List.generate(8, (i) => TeamStats('Ліга4 ${i + 1}', 10, 3 - i, i, i % 2, 12 - i, 13 + i)),
    'П\'ята ліга': List.generate(8, (i) => TeamStats('Ліга5 ${i + 1}', 10, 2 - i, i, i % 2, 10 - i, 14 + i)),
  };

  @override
  Widget build(BuildContext context) {
    final showAll = selectedLeague == 'Усі ліги';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: selectedLeague,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              onChanged: (value) => setState(() => selectedLeague = value!),
              items: leagues.map((league) {
                return DropdownMenuItem(
                  value: league,
                  child: Text(league, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (showAll)
                ...standings.entries.map((entry) => _LeagueBlock(
                      leagueName: entry.key,
                      teams: entry.value,
                    )),
              if (!showAll)
                _LeagueBlock(
                  leagueName: selectedLeague,
                  teams: standings[selectedLeague] ?? [],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeagueBlock extends StatelessWidget {
  const _LeagueBlock({required this.leagueName, required this.teams});

  final String leagueName;
  final List<TeamStats> teams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          leagueName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.orange),
        ),
        const SizedBox(height: 6),
        const _TableHeader(),
        ...teams.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final team = entry.value;
          return _TeamRow(index: index, team: team);
        }),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 4, child: Text('Клуб', style: _headerStyle)),
        Expanded(child: Text('І', style: _headerStyle)),
        Expanded(child: Text('В', style: _headerStyle)),
        Expanded(child: Text('Н', style: _headerStyle)),
        Expanded(child: Text('П', style: _headerStyle)),
        Expanded(child: Text('ЗМ', style: _headerStyle)),
        Expanded(child: Text('ПМ', style: _headerStyle)),
        Expanded(child: Text('РМ', style: _headerStyle)),
        Expanded(child: Text('О', style: _headerStyle)),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.index, required this.team});

  final int index;
  final TeamStats team;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('$index. ${team.name}', style: const TextStyle(color: Colors.white))),
          Expanded(child: Text('${team.played}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.wins}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.draws}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.losses}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.goalsFor}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.goalsAgainst}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.goalDifference}', textAlign: TextAlign.center)),
          Expanded(child: Text('${team.points}', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class TeamStats {
  final String name;
  final int played, wins, draws, losses, goalsFor, goalsAgainst;

  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;

  TeamStats(
    this.name,
    this.played,
    this.wins,
    this.draws,
    this.losses,
    this.goalsFor,
    this.goalsAgainst,
  );
}

const _headerStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.orange,
);
