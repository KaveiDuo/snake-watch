import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'campus_boundary.dart';
import 'open_areas.dart';
import 'places.dart';
import 'species.dart';
import 'zones.dart';

/// IIT Guwahati campus (real coordinates, from OpenStreetMap).
const campusCenter = LatLng(26.1895, 91.6965);
final campusBounds = LatLngBounds(const LatLng(26.1780, 91.6820), const LatLng(26.2010, 91.7070));

/// Where "You" is shown when GPS is off, denied, or you're not on campus.
const demoYou = LatLng(26.19018, 91.70098); // beside Kameng Hostel

/// A spot counts as inside a building's premises if it is in the outline or
/// within this many metres of it (courtyards, entrances, parking).
const premisesMarginMetres = 20.0;

const _dist = Distance();

bool _inPolygon(LatLng p, List<LatLng> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.latitude > p.latitude) != (b.latitude > p.latitude) &&
        p.longitude < (b.longitude - a.longitude) * (p.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}

double _distToPolygon(LatLng p, List<LatLng> poly) => poly.map((v) => _dist.as(LengthUnit.Meter, p, v)).reduce(min);

/// Hostel or campus building whose premises contain [p], or null for an
/// open area (road, field, lake, forest…). Inside an outline wins; otherwise
/// the nearest building within [premisesMarginMetres].
Zone? zoneAt(LatLng p) {
  for (final z in campusZones) {
    if (z.outlines.any((o) => _inPolygon(p, o))) return z;
  }
  Zone? best;
  var bestD = premisesMarginMetres;
  for (final z in campusZones) {
    for (final o in z.outlines) {
      final d = _distToPolygon(p, o);
      if (d <= bestD) {
        bestD = d;
        best = z;
      }
    }
  }
  return best;
}

/// Metres from [p] to the segment a–b (flat-earth approximation, fine at campus scale).
double _distToSegment(LatLng p, LatLng a, LatLng b) {
  const mPerDegLat = 111320.0;
  final mPerDegLon = 111320.0 * cos(p.latitude * pi / 180);
  final ax = (a.longitude - p.longitude) * mPerDegLon, ay = (a.latitude - p.latitude) * mPerDegLat;
  final bx = (b.longitude - p.longitude) * mPerDegLon, by = (b.latitude - p.latitude) * mPerDegLat;
  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
  final x = ax + t * dx, y = ay + t * dy;
  return sqrt(x * x + y * y);
}

double _distToLine(LatLng p, List<LatLng> line) {
  var best = double.infinity;
  for (var i = 0; i + 1 < line.length; i++) {
    best = min(best, _distToSegment(p, line[i], line[i + 1]));
  }
  return best;
}

/// Name for a spot outside any building: the field, court, park or lake it is
/// in, the road it is on, or just "Open area".
String openAreaName(LatLng p) {
  for (final (name, outline) in openFields) {
    if (_inPolygon(p, outline)) return name;
  }
  for (final (name, outline) in openWater) {
    if (_inPolygon(p, outline)) return name;
  }
  if (mainRoadLines.any((l) => _distToLine(p, l) <= 14)) return 'North Guwahati Road';
  if (campusRoadLines.any((l) => _distToLine(p, l) <= 10)) {
    String? best;
    var bestD = 170.0;
    for (final (name, at) in roadNameLabels) {
      final d = _dist.as(LengthUnit.Meter, p, at);
      if (d < bestD) {
        bestD = d;
        best = name;
      }
    }
    return best ?? 'Campus road';
  }
  for (final (name, outline) in openWater) {
    if (_distToLine(p, outline) <= 15) return '$name bank';
  }
  return 'Open area';
}

/// Inside the IIT Guwahati campus boundary (or on a building we know about).
bool onCampus(LatLng p) => _inPolygon(p, campusBoundary) || zoneAt(p) != null;

LatLng zoneCentre(String name) {
  final pts = campusZones.firstWhere((z) => z.name == name).outlines.first;
  return LatLng(
    pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length,
    pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length,
  );
}

enum Venom { venomous, harmless, unsure }

enum Role { none, student, authority }

class Loc {
  final String name;
  final String source;
  final bool covered;
  final LatLng pos;

  /// True when the spot is outside the IIT Guwahati campus (can't be reported).
  final bool outside;
  const Loc(this.name, this.source, {required this.covered, this.pos = demoYou, this.outside = false});
  String get authority => '$name authority';
}

class Report {
  final String id;
  final String? speciesId;
  final Venom venom;
  final String place;
  final String spot;
  final String note;
  final String reporter;
  final DateTime time;
  final LatLng pos;
  final bool covered;
  final String? photoPath;
  bool safe;

  Report({
    required this.id,
    required this.venom,
    required this.place,
    required this.pos,
    required this.covered,
    this.speciesId,
    this.spot = '',
    this.note = '',
    this.reporter = 'Ananya S.',
    DateTime? time,
    this.photoPath,
    this.safe = false,
  }) : time = time ?? DateTime.now();

  Species? get sp => speciesId == null ? null : speciesById(speciesId!);
  String get title => sp?.name ?? (venom == Venom.harmless ? 'Harmless snake' : 'Unidentified snake');
  String get where => spot.isEmpty ? place : '$place · $spot';
  bool get treatAsVenomous => venom != Venom.harmless;
}

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  return 'Yesterday';
}

class Draft {
  Loc? loc;
  Venom? venom;
  String? speciesId;
  String? photoPath;
  String? matchedId;
  bool exactSpotSet = false;
  String note = '';
}

enum GpsState { off, searching, onCampus, offCampus, denied }

class AppState extends ChangeNotifier {
  Role role = Role.none;
  bool mapDark = false; // light map first; the moon button switches to dark
  bool filterOpenOnly = false;
  final String authorityHostel = 'Kameng Hostel';
  final String studentName = 'Ananya Sharma';
  final String studentEmail = '210102043@iitg.ac.in';

  // ---------- GPS ----------
  GpsState gps = GpsState.off;
  LatLng you = demoYou;
  StreamSubscription<Position>? _gpsSub;

  /// Asks for location permission once and follows the phone's GPS.
  /// Off campus (or no permission) the demo location beside Kameng is used.
  Future<void> startGps() async {
    if (gps != GpsState.off) return;
    gps = GpsState.searching;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        gps = GpsState.denied;
        notifyListeners();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        gps = GpsState.denied;
        notifyListeners();
        return;
      }
      _gpsSub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5))
          .listen(
            _onPosition,
            onError: (_) {
              gps = GpsState.denied;
              notifyListeners();
            },
          );
      _onPosition(await Geolocator.getCurrentPosition());
    } catch (_) {
      gps = GpsState.denied;
      notifyListeners();
    }
  }

  void _onPosition(Position p) {
    final here = LatLng(p.latitude, p.longitude);
    if (campusBounds.contains(here)) {
      you = here;
      gps = GpsState.onCampus;
    } else {
      you = demoYou;
      gps = GpsState.offCampus;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  /// Location used for "Use my current location".
  Loc get currentLoc {
    final z = zoneAt(you);
    final source = gps == GpsState.onCampus ? 'Detected from your location' : 'Demo location (you’re off campus)';
    return z != null ? Loc(z.name, source, covered: true, pos: you) : Loc(openAreaName(you), source, covered: false, pos: you);
  }

  final List<Report> reports = [
    Report(
      id: 'r1',
      speciesId: 'banded_krait',
      venom: Venom.venomous,
      place: 'Kameng Hostel',
      spot: 'back gate',
      note: 'Went under the parked cycles near the back gate, hasn’t come out. Security has been told.',
      reporter: 'Ananya S.',
      time: DateTime.now().subtract(const Duration(minutes: 9)),
      pos: const LatLng(26.19068, 91.70186),
      covered: true,
    ),
    Report(
      id: 'r2',
      speciesId: 'keelback',
      venom: Venom.harmless,
      place: 'Kameng Hostel',
      spot: 'near the mess hall',
      note: 'Saw it near the mess hall drain this morning, it moved off toward the hedge.',
      reporter: 'Rohit K.',
      time: DateTime.now().subtract(const Duration(minutes: 32)),
      pos: const LatLng(26.19016, 91.70140),
      covered: true,
    ),
    Report(
      id: 'r3',
      venom: Venom.unsure,
      place: 'Lake-side Path',
      note: 'Dark snake crossed the path and went into the grass by the lake.',
      reporter: 'Priya D.',
      time: DateTime.now().subtract(const Duration(minutes: 41)),
      pos: const LatLng(26.19005, 91.69420),
      covered: false,
    ),
    Report(
      id: 'r4',
      speciesId: 'wolf',
      venom: Venom.harmless,
      place: 'Kameng Hostel',
      spot: 'near the parking area',
      note: 'Small banded snake near the bike parking, guard moved it to the green belt.',
      reporter: 'Meghna B.',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      pos: const LatLng(26.19080, 91.70128),
      covered: true,
      safe: true,
    ),
    Report(
      id: 'r5',
      speciesId: 'rat',
      venom: Venom.harmless,
      place: 'Core 3',
      spot: 'rear stairs',
      note: 'Long snake on the rear stairs, went under the steps.',
      reporter: 'Arjun M.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      pos: const LatLng(26.18590, 91.69060),
      covered: true,
      safe: true,
    ),
  ];

  Draft draft = Draft();

  // ---------- campus ----------
  List<Report> get openReports => reports.where((r) => !r.safe).toList();
  int get activeCount => openReports.length;
  Report? get latestOpen {
    final o = openReports..sort((a, b) => b.time.compareTo(a.time));
    return o.isEmpty ? null : o.first;
  }

  double metresFromYou(LatLng p) => _dist.as(LengthUnit.Meter, you, p);

  // ---------- hostel authority ----------
  List<Report> get hostelReports =>
      reports.where((r) => r.covered && r.place == authorityHostel).toList()..sort((a, b) => b.time.compareTo(a.time));
  int get hostelOpen => hostelReports.where((r) => !r.safe).length;
  int safeThisWeek = 5;

  void setRole(Role r) {
    role = r;
    notifyListeners();
  }

  void toggleMap() {
    mapDark = !mapDark;
    notifyListeners();
  }

  void toggleFilter() {
    filterOpenOnly = !filterOpenOnly;
    notifyListeners();
  }

  void markSafe(Report r, bool safe) {
    r.safe = safe;
    safeThisWeek += safe ? 1 : -1;
    notifyListeners();
  }

  // ---------- reporting ----------
  void startDraft({Loc? at}) {
    draft = Draft()..loc = at;
    notifyListeners();
  }

  void setDraftLoc(Loc loc) {
    draft.loc = loc;
    notifyListeners();
  }

  void setVenom(Venom v) {
    draft.venom = v;
    final s = draft.speciesId;
    if (s != null && speciesById(s).venomous != (v == Venom.venomous) && v != Venom.unsure) draft.speciesId = null;
    notifyListeners();
  }

  void setSpecies(String? id) {
    draft.speciesId = draft.speciesId == id ? null : id;
    notifyListeners();
  }

  void setPhoto(String? path, {String? matchedId}) {
    draft.photoPath = path;
    draft.matchedId = matchedId;
    if (matchedId != null) {
      draft.speciesId = matchedId;
      draft.venom = speciesById(matchedId).venomous ? Venom.venomous : Venom.harmless;
    }
    notifyListeners();
  }

  Report submit() {
    final loc = draft.loc ?? currentLoc;
    final r = Report(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      speciesId: draft.speciesId,
      venom: draft.venom ?? Venom.unsure,
      place: loc.name,
      note: draft.note,
      reporter: 'Ananya S.',
      pos: loc.pos,
      covered: loc.covered,
      photoPath: draft.photoPath,
    );
    reports.insert(0, r);
    notifyListeners();
    return r;
  }

  /// Place picked from the list. Buildings with an OpenStreetMap outline use
  /// its real position; the rest get an approximate spot on campus (demo).
  Loc locFromList(Place place, bool covered) {
    LatLng pos;
    if (place.zone != null) {
      pos = zoneCentre(place.zone!);
    } else {
      final rnd = Random(place.label.hashCode);
      pos = LatLng(campusCenter.latitude + (rnd.nextDouble() - 0.5) * 0.008, campusCenter.longitude + (rnd.nextDouble() - 0.5) * 0.012);
    }
    return Loc(place.label, 'Chosen from the list', covered: covered, pos: pos);
  }

  /// Place picked by tapping the map: a hostel or campus building if the pin
  /// is on its premises, otherwise an open area (no authority).
  Loc locFromMap(LatLng p) {
    if (!onCampus(p)) {
      return Loc('Outside IIT Guwahati campus', 'Pinned on the map', covered: false, pos: p, outside: true);
    }
    final z = zoneAt(p);
    return z != null
        ? Loc(z.name, 'Pinned on the map', covered: true, pos: p)
        : Loc(openAreaName(p), 'Pinned on the map', covered: false, pos: p);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
