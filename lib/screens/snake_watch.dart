import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/campus_map.dart';
import '../widgets/common.dart';
import 'report.dart';
import 'sighting_detail.dart';
import 'snake_guide.dart';

class SnakeWatchScreen extends StatelessWidget {
  const SnakeWatchScreen({super.key});

  void _report(BuildContext context, {Loc? at}) {
    AppScope.read(context).startDraft(at: at);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return DarkPage(
      header: AppHeader(
        'Snake Watch',
        subtitle: s.activeCount == 1 ? '1 active report on campus' : '${s.activeCount} active reports on campus',
        trailing: RoundButton(Icons.menu_book_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnakeGuideScreen()))),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: CampusMap(
                  dark: s.mapDark,
                  reports: s.reports,
                  onToggleTheme: s.toggleMap,
                  onTapReport: (r) => Navigator.push(context, MaterialPageRoute(builder: (_) => SightingDetailScreen(report: r))),
                  onTapMap: (p) => _report(context, at: s.locFromMap(p)),
                  controlsPadding: const EdgeInsets.fromLTRB(10, 10, 10, 44),
                  topHint: _Hint('Tap anywhere on the map to report a sighting there', dark: s.mapDark),
                ),
              ),
              Positioned(left: 10, bottom: 10, right: 60, child: _Legend(dark: s.mapDark)),
            ]),
          ),
          const SizedBox(height: 12),
          Material(
            color: C.red,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _report(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
                child: Row(children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Report a sighting', style: ft(17, w: 600, color: Colors.white)),
                      Text('Uses your current location · you can change it', style: ft(12.5, color: Colors.white.withValues(alpha: 0.85))),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final bool dark;
  const _Hint(this.text, {required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: dark ? const Color(0xE61C1C1C) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dark ? C.line2 : const Color(0xFFDDDDDD)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: ft(12, color: dark ? C.text : const Color(0xFF222222))),
      );
}

class _Legend extends StatelessWidget {
  final bool dark;
  const _Legend({required this.dark});
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Venomous', const Color(0xFFFF453A)),
      ('Harmless', const Color(0xFF2DD4BF)),
      ('Unsure', C.amber),
      ('Safe', const Color(0xFF8A8A8A)),
      ('You', C.blue),
    ];
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: dark ? const Color(0xE61C1C1C) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dark ? C.line2 : const Color(0xFFDDDDDD)),
        ),
        child: Wrap(spacing: 9, runSpacing: 4, children: [
          for (final (l, c) in items)
            Row(mainAxisSize: MainAxisSize.min, children: [
              l == 'You'
                  ? Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle))
                  : LocationPin(color: c, width: 9),
              const SizedBox(width: 4),
              Text(l, style: ft(11, color: dark ? C.text : const Color(0xFF222222))),
            ]),
        ]),
      ),
    );
  }
}
