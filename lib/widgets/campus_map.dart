import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Teardrop "location" pin with a white outline and a white centre dot.
/// The tip of the pin points at the reported spot.
class LocationPin extends StatelessWidget {
  final Color color;
  final double width;
  const LocationPin({super.key, required this.color, this.width = 26});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, width * 1.3), painter: _PinPainter(color));
}

class _PinPainter extends CustomPainter {
  final Color color;
  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, r = w / 2;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.36, h * 0.8, 0, h * 0.62, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..cubicTo(w, h * 0.62, w * 0.64, h * 0.8, w / 2, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08);
    canvas.drawCircle(Offset(w / 2, r), w * 0.17, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}

/// Real, zoomable campus map: pinch/drag to move, + / − buttons, tap to pick.
/// Markers are drawn on top of the map so they stay the same size when zooming.
class CampusMap extends StatefulWidget {
  final bool dark;
  final List<Report> reports;
  final Offset? selected;
  final void Function(Offset mapPoint)? onTapMap;
  final void Function(Report r)? onTapReport;
  final bool showZone;
  final EdgeInsets controlsPadding;
  final Widget? topHint;
  final VoidCallback? onToggleTheme;
  const CampusMap({
    super.key,
    required this.dark,
    this.reports = const [],
    this.selected,
    this.onTapMap,
    this.onTapReport,
    this.showZone = false,
    this.controlsPadding = const EdgeInsets.all(10),
    this.topHint,
    this.onToggleTheme,
  });

  @override
  State<CampusMap> createState() => CampusMapState();
}

class CampusMapState extends State<CampusMap> with TickerProviderStateMixin {
  final _tc = TransformationController();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  Animation<Matrix4>? _zoomAnim;
  Size _viewport = Size.zero;
  double _s0 = 1;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_zoomAnim != null) _tc.value = _zoomAnim!.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulse.dispose();
    _tc.dispose();
    super.dispose();
  }

  double get _scale => _tc.value.getMaxScaleOnAxis();

  void _animateTo(Matrix4 target) {
    _zoomAnim = Matrix4Tween(begin: _tc.value, end: target).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _anim.forward(from: 0);
  }

  Matrix4 _clamp(Matrix4 m) {
    final s = m.getMaxScaleOnAxis();
    final cw = mapSize.width * _s0 * s, ch = mapSize.height * _s0 * s;
    final t = m.getTranslation();
    final tx = t.x.clamp(_viewport.width - cw, 0.0);
    final ty = t.y.clamp(_viewport.height - ch, 0.0);
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void zoom(double factor) {
    final target = (_scale * factor).clamp(1.0, 4.0);
    final f = target / _scale;
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(_tc.value);
    _animateTo(_clamp(m));
  }

  void centerOn(Offset mapPoint) {
    final s = _scale;
    final m = Matrix4.identity()
      ..translateByDouble(_viewport.width / 2 - mapPoint.dx * _s0 * s, _viewport.height / 2 - mapPoint.dy * _s0 * s, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    _animateTo(_clamp(m));
  }

  Offset _toScreen(Offset mapPoint) => MatrixUtils.transformPoint(_tc.value, mapPoint * _s0);
  Offset _toMap(Offset screen) => _tc.toScene(screen) / _s0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _viewport = box.biggest;
      _s0 = _viewport.width / mapSize.width;
      if (!_placed) {
        _placed = true;
        final ty = (_viewport.height / 2 - youAreHere.dy * _s0).clamp(_viewport.height - mapSize.height * _s0, 0.0);
        _tc.value = Matrix4.identity()..translateByDouble(0, ty, 0, 1);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final p = _toMap(d.localPosition);
                // Tapping near a report pin opens it; anywhere else picks the spot.
                if (widget.onTapReport != null) {
                  for (final r in widget.reports) {
                    // Hit area is the pin's head, which sits above the reported spot.
                    if ((_toScreen(r.pos) - const Offset(0, 20) - d.localPosition).distance < 22) {
                      widget.onTapReport!(r);
                      return;
                    }
                  }
                }
                widget.onTapMap?.call(p);
              },
              child: InteractiveViewer(
                transformationController: _tc,
                constrained: false,
                minScale: 1,
                maxScale: 4,
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  width: mapSize.width * _s0,
                  height: mapSize.height * _s0,
                  child: Image.asset(
                    widget.dark ? 'assets/images/pick_map_dark.png' : 'assets/images/pick_map_light.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          // Markers (fixed size, follow the map)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_tc, _pulse]),
                builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
                  if (widget.showZone) _zone(),
                  _you(),
                  for (final r in widget.reports) _pin(r),
                  if (widget.selected != null) ..._selected(widget.selected!),
                ]),
              ),
            ),
          ),
          if (widget.topHint != null) Positioned(left: 10, top: 10, right: 58, child: widget.topHint!),
          Positioned(
            right: widget.controlsPadding.right,
            top: widget.controlsPadding.top,
            child: Column(children: [
              _ctl(Icons.add_rounded, () => zoom(1.6)),
              const SizedBox(height: 6),
              _ctl(Icons.remove_rounded, () => zoom(1 / 1.6)),
            ]),
          ),
          Positioned(
            right: widget.controlsPadding.right,
            bottom: widget.controlsPadding.bottom,
            child: Column(children: [
              _ctl(Icons.my_location_rounded, () => centerOn(youAreHere), color: C.blue),
              if (widget.onToggleTheme != null) ...[
                const SizedBox(height: 8),
                _ctl(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, widget.onToggleTheme!),
              ],
            ]),
          ),
        ]),
      );
    });
  }

  Widget _ctl(IconData icon, VoidCallback onTap, {Color? color}) => Material(
        color: widget.dark ? const Color(0xE61C1C1C) : const Color(0xF2FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: widget.dark ? C.line2 : const Color(0xFFDDDDDD)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: color ?? (widget.dark ? C.text : const Color(0xFF222222)))),
        ),
      );

  Widget _zone() {
    final a = _toScreen(kamengZone.topLeft), b = _toScreen(kamengZone.bottomRight);
    return Positioned.fromRect(
      rect: Rect.fromPoints(a, b),
      child: Container(
        decoration: BoxDecoration(
          color: C.green.withValues(alpha: 0.08),
          border: Border.all(color: C.green.withValues(alpha: 0.55), width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(4),
        child: Text('Kameng', style: ft(9.5, w: 700, color: C.green)),
      ),
    );
  }

  static const _pinW = 26.0, _pinH = _pinW * 1.3;

  Widget _pin(Report r) {
    final s = _toScreen(r.pos);
    final c = pinColor(r);
    final t = _pulse.value;
    return Positioned(
      left: s.dx - 24,
      top: s.dy - _pinH,
      child: SizedBox(
        width: 48,
        height: _pinH + 8,
        child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: [
          // Ripple on the ground under open reports
          if (!r.safe)
            Positioned(
              top: _pinH - (4 + 5 * t),
              child: Container(
                width: 8 + 34 * t,
                height: 8 + 10 * t,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(21 + 17 * t, 5 + 5 * t)),
                  color: c.withValues(alpha: 0.45 * (1 - t)),
                ),
              ),
            ),
          LocationPin(color: c, width: _pinW),
        ]),
      ),
    );
  }

  Widget _you() {
    final s = _toScreen(youAreHere);
    return Positioned(
      left: s.dx - 20,
      top: s.dy - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: C.blue.withValues(alpha: 0.18), border: Border.all(color: C.blue.withValues(alpha: 0.45))),
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.blue, border: Border.all(color: Colors.white, width: 3)),
        ),
      ),
    );
  }

  List<Widget> _selected(Offset p) {
    final s = _toScreen(p);
    return [
      Positioned(
        left: s.dx - 22,
        top: s.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.green.withValues(alpha: 0.18), border: Border.all(color: C.green, width: 1.5)),
        ),
      ),
      Positioned(left: s.dx - 15, top: s.dy - 39, child: const LocationPin(color: C.green, width: 30)),
    ];
  }
}
