import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/species.dart';
import '../theme.dart';
import '../widgets/common.dart';

class IdentifyResult {
  final String photoPath;
  final String speciesId;
  const IdentifyResult(this.photoPath, this.speciesId);
}

/// Demo "Identify snake": pick or take a photo, a short scanning animation
/// plays, then a pretend match is shown. There is no real AI model in this
/// demo — the sample photos return their own species, your own photos
/// return Banded Krait.
class IdentifyScreen extends StatefulWidget {
  final bool forReport;
  const IdentifyScreen({super.key, this.forReport = false});
  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> with SingleTickerProviderStateMixin {
  static const samples = ['banded_krait', 'cobra', 'keelback', 'wolf', 'vine', 'rat', 'king_cobra', 'python', 'black_krait'];
  String? _photo;
  String _match = 'banded_krait';
  bool _scanning = false;
  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Future<void> _start(String photo, String match) async {
    setState(() {
      _photo = photo;
      _match = match;
      _scanning = true;
    });
    _scan.repeat(reverse: true, period: const Duration(milliseconds: 900));
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    _scan.stop();
    setState(() => _scanning = false);
  }

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (x != null) _start(x.path, 'banded_krait');
  }

  Widget _image(String path, {BoxFit fit = BoxFit.cover}) =>
      path.startsWith('assets/') ? Image.asset(path, fit: fit) : Image.file(File(path), fit: fit);

  @override
  Widget build(BuildContext context) {
    final title = _photo == null ? 'Choose a photo' : 'Identify snake';
    return DarkPage(
      header: AppHeader(title, backIcon: Icons.close_rounded),
      body: _photo == null ? _chooser() : (_scanning ? _scanner() : _result()),
    );
  }

  Widget _chooser() => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Row(children: [
          Expanded(child: Btn('Take a photo', icon: Icons.photo_camera_outlined, height: 48, onTap: () => _pick(ImageSource.camera))),
          const SizedBox(width: 10),
          Expanded(child: Btn('Gallery', kind: BtnKind.ghost, icon: Icons.photo_library_outlined, height: 48, onTap: () => _pick(ImageSource.gallery))),
        ]),
        const SizedBox(height: 22),
        Text('OR TRY A SAMPLE PHOTO', style: ft(11.5, w: 700, color: C.muted, ls: 1.2)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final id in samples)
              GestureDetector(
                onTap: () => _start(speciesById(id).photo, id),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(speciesById(id).photo, fit: BoxFit.cover)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Pick a clear photo of the whole snake for the best match. Keep 3 m back — zoom in instead.', style: ft(12.5, color: C.muted, height: 1.5)),
      ]);

  Widget _scanner() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            _image(_photo!),
            Container(color: Colors.black.withValues(alpha: 0.2)),
            AnimatedBuilder(
              animation: _scan,
              builder: (context, _) => Align(
                alignment: Alignment(0, -0.9 + 1.8 * _scan.value),
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: C.green, boxShadow: [BoxShadow(color: C.green.withValues(alpha: 0.7), blurRadius: 18, spreadRadius: 2)]),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Text('Matching against campus species…', textAlign: TextAlign.center, style: ft(13.5, w: 600, color: Colors.white)),
            ),
          ]),
        ),
      );

  Widget _result() {
    final sp = speciesById(_match);
    final others = species.where((x) => x.id != sp.id && (x.id == 'wolf' || x.id == 'cobra' || x.id == 'keelback')).take(2).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      ClipRRect(borderRadius: BorderRadius.circular(22), child: AspectRatio(aspectRatio: 1.1, child: _image(_photo!))),
      const SizedBox(height: 12),
      Panel(
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 64, height: 64, child: Image.asset(sp.photo, fit: BoxFit.cover))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tag(sp.venomous ? 'VENOMOUS' : 'NON-VENOMOUS', fg: sp.venomous ? C.redText : C.greenText, bg: sp.venomous ? C.redSoft : C.greenSoft),
              const SizedBox(height: 6),
              Text(sp.name, style: ft(17, w: 700)),
              Text(sp.latin, style: ft(12, color: C.muted).copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(value: 0.76, minHeight: 5, color: C.green, backgroundColor: Color(0xFF2A2A2A)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('76%', style: ft(13, w: 700, color: C.green)),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Text('Demo match, not a diagnosis. If it doesn’t look right, pick an alternative or report as Not sure.',
          style: ft(12, color: C.muted, height: 1.4)),
      const SizedBox(height: 16),
      Text('OTHER POSSIBLE MATCHES', style: ft(11.5, w: 700, color: C.muted, ls: 1.2)),
      const SizedBox(height: 8),
      for (final (i, o) in others.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Panel(
            padding: const EdgeInsets.all(10),
            onTap: () => setState(() => _match = o.id),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 44, height: 44, child: Image.asset(o.photo, fit: BoxFit.cover))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.name, style: ft(14.5, w: 600)),
                  Text(o.venomous ? 'Venomous' : 'Non-venomous', style: ft(12, color: C.muted)),
                ]),
              ),
              Text(i == 0 ? '18%' : '6%', style: ft(13, color: C.muted)),
            ]),
          ),
        ),
      const SizedBox(height: 10),
      if (widget.forReport) Btn('Use this in my report', onTap: () => Navigator.pop(context, IdentifyResult(_photo!, _match))),
      const SizedBox(height: 8),
      Btn('Retake photo', kind: BtnKind.ghost, onTap: () => setState(() => _photo = null)),
    ]);
  }
}
