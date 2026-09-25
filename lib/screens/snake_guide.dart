import 'package:flutter/material.dart';

import '../data/species.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'identify.dart';

class SnakeGuideScreen extends StatefulWidget {
  const SnakeGuideScreen({super.key});
  @override
  State<SnakeGuideScreen> createState() => _SnakeGuideScreenState();
}

class _SnakeGuideScreenState extends State<SnakeGuideScreen> {
  int _filter = 0; // 0 all, 1 venomous, 2 harmless

  @override
  Widget build(BuildContext context) {
    final venomous = species.where((s) => s.venomous).toList();
    final harmless = species.where((s) => !s.venomous).toList();
    return DarkPage(
      header: AppHeader(
        'Snake Guide',
        subtitle: '${species.length} species recorded around Guwahati',
        trailing: RoundButton(Icons.center_focus_strong_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentifyScreen()))),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 30), children: [
        Row(children: [
          for (final (i, label, n) in [(0, 'All', species.length), (1, 'Venomous', venomous.length), (2, 'Harmless', harmless.length)])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: _filter == i,
                onSelected: (_) => setState(() => _filter = i),
                showCheckmark: false,
                label: Text('$label  $n', style: ft(13, w: 600, color: _filter == i ? C.greenInk : C.sub)),
                selectedColor: C.green,
                backgroundColor: C.card,
                side: BorderSide(color: _filter == i ? C.green : C.line2),
                shape: const StadiumBorder(),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
          child: Text('Reference photos only — never handle a snake to identify it. Treat every unidentified snake as venomous.',
              style: ft(12.5, color: C.muted, height: 1.45)),
        ),
        if (_filter != 2) ...[
          _section('VENOMOUS · ${venomous.length} — TREAT AS DANGEROUS', C.redText),
          for (final s in venomous) _SpeciesTile(s),
        ],
        if (_filter != 1) ...[
          _section('HARMLESS TO PEOPLE · ${harmless.length}', C.greenText),
          for (final s in harmless) _SpeciesTile(s),
        ],
        const SizedBox(height: 18),
        Text('PHOTO CREDITS', style: ft(11, w: 700, color: C.muted, ls: 1.2)),
        const SizedBox(height: 6),
        Text(photoCredits, style: ft(10.5, color: C.faint, height: 1.5)),
        const SizedBox(height: 8),
        Text(
          'Species list based on published surveys of Guwahati (Purkayastha 2018) and the Gauhati University campus (Gogoi et al. 2023). '
          'Not every snake here has been recorded at IIT Guwahati itself.',
          style: ft(10.5, color: C.faint, height: 1.5),
        ),
      ]),
    );
  }

  Widget _section(String t, Color c) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 0, 10),
        child: Text(t, style: ft(11.5, w: 700, color: c, ls: 1)),
      );
}

class _SpeciesTile extends StatelessWidget {
  final Species s;
  const _SpeciesTile(this.s);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(12),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: C.card,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(aspectRatio: 1.5, child: Image.asset(s.photo, fit: BoxFit.cover)),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Tag(s.venomous ? 'VENOMOUS' : 'HARMLESS', fg: s.venomous ? C.redText : C.greenText, bg: s.venomous ? C.redSoft : C.greenSoft),
                    const SizedBox(height: 8),
                    Text(s.name, style: ft(22, w: 700)),
                    Text(s.latin, style: ft(13, color: C.muted).copyWith(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    Text(s.about, style: ft(14.5, color: C.sub, height: 1.5)),
                  ]),
                ),
              ]),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 72, height: 72, child: Image.asset(s.photo, fit: BoxFit.cover))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tag(s.venomous ? 'VENOMOUS' : 'HARMLESS', fg: s.venomous ? C.redText : C.greenText, bg: s.venomous ? C.redSoft : C.greenSoft),
                const SizedBox(height: 5),
                Text(s.name, style: ft(15, w: 700)),
                Text(s.latin, style: ft(11.5, color: C.muted).copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 5),
                Text(s.about, style: ft(12.5, color: C.sub, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
}
