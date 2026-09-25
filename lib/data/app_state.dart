import 'dart:math';

import 'package:flutter/widgets.dart';

import 'places.dart';
import 'species.dart';

/// Map coordinates are in "map pixels" of the 398 × 760 campus map
/// (assets/images/pick_map_*.png is exported at 2×).
const mapSize = Size(398, 760);
const youAreHere = Offset(282, 388);

/// Demo geofence: only Kameng Hostel's boundary is drawn. Taps inside it are
/// covered by the Kameng hostel authority; anywhere else counts as an open area.
const kamengZone = Rect.fromLTRB(284, 364, 340, 432);

enum Venom { venomous, harmless, unsure }

enum Role { none, student, authority }

class Loc {
  final String name;
  final String source;
  final bool covered;
  final Offset pos;
  const Loc(this.name, this.source, {required this.covered, this.pos = youAreHere});
  String get authority => '$name authority';
}

const detectedLoc = Loc('Kameng Hostel', 'Detected from your location', covered: true, pos: Offset(307, 392));

class Report {
  final String id;
  final String? speciesId;
  final Venom venom;
  final String place;
  final String spot;
  final String note;
  final String reporter;
  final DateTime time;
  final Offset pos;
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

class AppState extends ChangeNotifier {
  Role role = Role.none;
  bool mapDark = true;
  bool filterOpenOnly = false;
  final String authorityHostel = 'Kameng Hostel';
  final String studentName = 'Ananya Sharma';
  final String studentEmail = '210102043@iitg.ac.in';

  final List<Report> reports = [
    Report(
      id: 'r1', speciesId: 'banded_krait', venom: Venom.venomous, place: 'Kameng Hostel', spot: 'back gate',
      note: 'Went under the parked cycles near the back gate, hasn’t come out. Security has been told.',
      reporter: 'Ananya S.', time: DateTime.now().subtract(const Duration(minutes: 9)),
      pos: const Offset(313, 405), covered: true,
    ),
    Report(
      id: 'r2', speciesId: 'keelback', venom: Venom.harmless, place: 'Kameng Hostel', spot: 'near the mess hall',
      note: 'Saw it near the mess hall drain this morning, it moved off toward the hedge.',
      reporter: 'Rohit K.', time: DateTime.now().subtract(const Duration(minutes: 32)),
      pos: const Offset(296, 426), covered: true,
    ),
    Report(
      id: 'r3', venom: Venom.unsure, place: 'Lake-side Path',
      note: 'Dark snake crossed the path and went into the grass by the lake.',
      reporter: 'Priya D.', time: DateTime.now().subtract(const Duration(minutes: 41)),
      pos: const Offset(184, 392), covered: false,
    ),
    Report(
      id: 'r4', speciesId: 'wolf', venom: Venom.harmless, place: 'Kameng Hostel', spot: 'near the parking area',
      note: 'Small banded snake near the bike parking, guard moved it to the green belt.',
      reporter: 'Meghna B.', time: DateTime.now().subtract(const Duration(hours: 1)),
      pos: const Offset(326, 440), covered: true, safe: true,
    ),
    Report(
      id: 'r5', speciesId: 'rat', venom: Venom.harmless, place: 'Core 3', spot: 'rear stairs',
      note: 'Long snake on the rear stairs, went under the steps.',
      reporter: 'Arjun M.', time: DateTime.now().subtract(const Duration(hours: 2)),
      pos: const Offset(150, 461), covered: false, safe: true,
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
    final loc = draft.loc ?? detectedLoc;
    final rnd = Random();
    final r = Report(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      speciesId: draft.speciesId,
      venom: draft.venom ?? Venom.unsure,
      place: loc.name,
      note: draft.note,
      reporter: 'Ananya S.',
      pos: loc.pos + Offset(rnd.nextDouble() * 6 - 3, rnd.nextDouble() * 6 - 3),
      covered: loc.covered,
      photoPath: draft.photoPath,
    );
    reports.insert(0, r);
    notifyListeners();
    return r;
  }

  /// Place picked from the list. Hostels are covered by their authority.
  Loc locFromList(String place, bool hostel) {
    final rnd = Random(place.hashCode);
    final pos = hostel && place == 'Kameng'
        ? const Offset(307, 392)
        : Offset(60 + rnd.nextDouble() * 280, 260 + rnd.nextDouble() * 260);
    return Loc(placeLabel(place, hostel), 'Chosen from the list', covered: hostel, pos: pos);
  }

  /// Place picked by tapping the map.
  Loc locFromMap(Offset p) =>
      kamengZone.contains(p)
          ? Loc('Kameng Hostel', 'Pinned on the map', covered: true, pos: p)
          : Loc('Open area', 'Pinned on the map', covered: false, pos: p);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
