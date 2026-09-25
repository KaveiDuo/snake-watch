/// Places shown in the "Select location" sheet.
///
/// Buildings (hostels, academic and campus buildings, schools) have an
/// authority: a report there goes to that building's authority. Open areas
/// (roads, fields, lakes, forest, gates) are pin-only: students see the pin,
/// no authority is notified, and it clears itself after 2–3 days.
class Place {
  final String label;

  /// Name of the matching outline in `campusZones`, if OpenStreetMap has one.
  final String? zone;
  const Place(this.label, {this.zone});
}

class PlaceGroup {
  final String title;
  final bool covered;
  final List<Place> places;
  const PlaceGroup(this.title, this.places, {this.covered = true});
}

Place _hostel(String name) => Place('$name Hostel', zone: '$name Hostel');
Place _b(String name, [String? zone]) => Place(name, zone: zone ?? name);
Place _open(String name) => Place(name);

final placeGroups = <PlaceGroup>[
  PlaceGroup('HOSTELS', [
    for (final h in [
      'Lohit',
      'Brahmaputra',
      'Disang',
      'Kameng',
      'Barak',
      'Manas',
      'Dihing',
      'Umiam',
      'Siang',
      'Kapili',
      'Dhansiri',
      'Subansiri',
      'Gaurang',
      'Dibang',
    ])
      _hostel(h),
    const Place('Married Scholars Hostel (MSH)', zone: 'Married Scholars Hostel'),
  ]),
  PlaceGroup('ACADEMIC BUILDINGS', [
    _b('Core 1', 'Academic Complex'),
    _b('Core 2', 'Academic Complex'),
    _b('Core 3', 'Academic Complex'),
    _b('Core 4', 'Academic Complex'),
    _b('Core 5'),
    _b('Lecture Halls'),
    const Place('Central Library'),
    _b('Administrative Block'),
    _b('Mechanical Workshop'),
    _b('Planning and Management Section'),
  ]),
  PlaceGroup('CAMPUS BUILDINGS', [
    _b('New SAC'),
    _b('Old SAC'),
    _b('Gymkhana (General Gym)'),
    _b('Food Court'),
    _b('Guest House'),
    _b('IITG Hospital'),
    _b('Bhupen Hazarika Auditorium'),
    _b('Conference Hall'),
    _b('Transit Complex'),
    _b('Market Complex'),
  ]),
  PlaceGroup('SCHOOLS', [const Place('Kendriya Vidyalaya (KV)'), _b('Faculty Higher Secondary School')]),
  PlaceGroup('FIELDS & PLAYGROUNDS', covered: false, [
    _open('Football Ground'),
    _open('Cricket Ground'),
    _open('Athletics Track'),
    _open("Children's Park"),
    _open('Botanical Garden / Green Belt'),
  ]),
  PlaceGroup('ROADS & PATHS', covered: false, [
    _open('Main Gate Road'),
    _open('Inner Ring Road'),
    _open('KV Road'),
    _open('Suryamukhi Road'),
    _open('Godhuli Gopal Road'),
    _open('Radhasura Road'),
    _open('View Point Road'),
    _open('IIT Border Road'),
    _open('Lake-side Path'),
    _open('Cycle Track behind Core'),
  ]),
  PlaceGroup('LAKES & FOREST', covered: false, [_open('Serpentine Lake bank'), _open('Tihor Lake bank'), _open('Forest / hill area')]),
  PlaceGroup('GATES', covered: false, [
    _open('Main Gate'),
    _open('KV Gate'),
    _open('Khoka Gate'),
    _open('A.S.E.B Gate'),
    _open('Faculty Gate'),
    _open('Lothia Baghicha Gate'),
  ]),
];
