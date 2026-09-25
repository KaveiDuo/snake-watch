import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../data/app_state.dart';
import '../data/zones.dart';
import '../theme.dart';
import 'common.dart';

/// Teardrop "location" pin with a white outline and a white centre dot.
/// The tip of the pin points at the reported spot.
class LocationPin extends StatelessWidget {
  final Color color;
  final double width;
  const LocationPin({super.key, required this.color, this.width = 26});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, width * 1.3), painter: _PinPainter(color));
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
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08,
    );
    canvas.drawCircle(Offset(w / 2, r), w * 0.17, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}

/// Live campus map (OpenStreetMap tiles). Pinch/drag to move,
/// + / − to zoom, tap a pin to open it, tap anywhere else to pick that spot.
class CampusMap extends StatefulWidget {
  final bool dark;
  final List<Report> reports;
  final LatLng? selected;
  final void Function(LatLng point)? onTapMap;
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
  final _map = MapController();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  AnimationController? _move;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).startGps();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _move?.dispose();
    super.dispose();
  }

  /// Smoothly moves/zooms the camera.
  void _animateTo(LatLng dest, double zoom) {
    _move?.dispose();
    final cam = _map.camera;
    final lat = Tween(begin: cam.center.latitude, end: dest.latitude);
    final lng = Tween(begin: cam.center.longitude, end: dest.longitude);
    final z = Tween(begin: cam.zoom, end: zoom);
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    final a = CurvedAnimation(parent: c, curve: Curves.easeInOut);
    c.addListener(() => _map.move(LatLng(lat.evaluate(a), lng.evaluate(a)), z.evaluate(a)));
    _move = c..forward();
  }

  void zoom(double by) {
    final cam = _map.camera;
    _animateTo(cam.center, (cam.zoom + by).clamp(14.5, 19.0));
  }

  void centerOn(LatLng p) => _animateTo(p, _map.camera.zoom < 17 ? 17 : _map.camera.zoom);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: widget.dark ? const Color(0xFF1A1A1A) : const Color(0xFFEDEBE6),
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: widget.selected ?? const LatLng(26.1888, 91.6962),
                  initialZoom: widget.selected != null ? 17.2 : 15.6,
                  // Open zoomed so every report (and you) fits on screen.
                  initialCameraFit: widget.selected == null && widget.reports.isNotEmpty
                      ? CameraFit.coordinates(
                          coordinates: [for (final r in widget.reports) r.pos, s.you],
                          padding: const EdgeInsets.fromLTRB(40, 90, 60, 80),
                          maxZoom: 17.5,
                        )
                      : null,
                  minZoom: 14.5,
                  maxZoom: 19,
                  cameraConstraint: CameraConstraint.containCenter(bounds: campusBounds),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  onTap: (_, p) => widget.onTapMap?.call(p),
                ),
                children: [
                  // Standard OpenStreetMap tiles (free, no key). Night mode
                  // darkens them with flutter_map's dark-mode tile filter.
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'in.iitg.onestop.snake_watch',
                    maxZoom: 19,
                    tileBuilder: widget.dark ? darkModeTileBuilder : null,
                  ),
                  if (widget.showZone)
                    PolygonLayer(
                      polygons: [
                        for (final z in campusZones)
                          for (final pts in z.outlines)
                            Polygon(
                              points: pts,
                              color: C.green.withValues(alpha: 0.16),
                              borderColor: C.green.withValues(alpha: 0.8),
                              borderStrokeWidth: 1.5,
                            ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(point: s.you, width: 44, height: 44, child: _you(s.gps)),
                      for (final r in widget.reports)
                        Marker(
                          point: r.pos,
                          width: 48,
                          height: _pinH + 8,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(onTap: () => widget.onTapReport?.call(r), child: _pin(r)),
                        ),
                      if (widget.selected != null) ...[
                        Marker(
                          point: widget.selected!,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: C.green.withValues(alpha: 0.18),
                              border: Border.all(color: C.green, width: 1.5),
                            ),
                          ),
                        ),
                        Marker(
                          point: widget.selected!,
                          width: 30,
                          height: 39,
                          alignment: Alignment.topCenter,
                          child: const LocationPin(color: C.green, width: 30),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.topHint != null) Positioned(left: 10, top: 10, right: 58, child: widget.topHint!),
          Positioned(
            right: widget.controlsPadding.right,
            top: widget.controlsPadding.top,
            child: Column(
              children: [_ctl(Icons.add_rounded, () => zoom(1)), const SizedBox(height: 6), _ctl(Icons.remove_rounded, () => zoom(-1))],
            ),
          ),
          Positioned(
            right: widget.controlsPadding.right,
            bottom: widget.controlsPadding.bottom + 14,
            child: Column(
              children: [
                _ctl(s.gps == GpsState.onCampus ? Icons.my_location_rounded : Icons.location_searching_rounded, () {
                  centerOn(s.you);
                  if (s.gps == GpsState.offCampus) toast(context, 'You’re not on campus — showing a demo location near Kameng');
                  if (s.gps == GpsState.denied) toast(context, 'Location is off — showing a demo location near Kameng');
                }, color: C.blue),
                if (widget.onToggleTheme != null) ...[
                  const SizedBox(height: 8),
                  _ctl(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, widget.onToggleTheme!),
                ],
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: (widget.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('© OpenStreetMap contributors', style: ft(9, color: widget.dark ? C.muted : const Color(0xFF555555))),
            ),
          ),
        ],
      ),
    );
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

  static const _pinW = 26.0, _pinH = _pinW * 1.3;

  Widget _pin(Report r) {
    final c = pinColor(r);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = _pulse.value;
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
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
          ],
        );
      },
    );
  }

  Widget _you(GpsState gps) {
    final live = gps == GpsState.onCampus;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: C.blue.withValues(alpha: live ? 0.18 : 0.10),
        border: Border.all(color: C.blue.withValues(alpha: live ? 0.45 : 0.25)),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: live ? C.blue : C.blue.withValues(alpha: 0.6),
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}
