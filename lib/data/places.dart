/// Campus places shown in the "Select location" sheet (from the Figma file).
class PlaceGroup {
  final String title;
  final bool hostels;
  final List<String> places;
  const PlaceGroup(this.title, this.places, {this.hostels = false});
}

const placeGroups = <PlaceGroup>[
  PlaceGroup('HOSTELS', [
    'Lohit', 'Brahmaputra', 'Disang', 'Kameng', 'Barak', 'Manas', 'Dihing', 'Umiam', 'Siang', 'Kapili',
    'Dhansiri', 'Subansiri', 'MSH', 'Gaurang', 'Dibang',
  ], hostels: true),
  PlaceGroup('ACADEMIC', [
    'Core 1 (Lecture Hall Complex)', 'Core 2', 'Core 3', 'Department Complex A', 'Department Complex B', 'Central Library',
  ]),
  PlaceGroup('COMMON AREAS', [
    'Central Canteen', 'Market Complex', "Students' Activity Centre (SAC)", 'Health Centre', 'Gymkhana / Sports Complex',
    'Guest House',
  ]),
  PlaceGroup('OUTDOORS & ROADS', [
    'Main Gate Road', 'Inner Ring Road', 'KV Road', 'Suryamukhi Road', 'Godhuli Gopal Road', 'Radhasura Road',
    'View Point Road', 'IIT Border Road', 'Football Ground', 'Botanical Garden / Green Belt', 'Lake-side Path',
    'Cycle Track behind Core',
  ]),
  PlaceGroup('LAKES', ['Serpentine Lake bank', 'Tihor Lake bank']),
  PlaceGroup('GATES', ['Main Gate', 'KV Gate', 'Khoka Gate', 'A.S.E.B Gate', 'Faculty Gate', 'Lothia Baghicha Gate']),
];

/// Display name for a place: hostels get "Hostel" appended ("Barak Hostel").
String placeLabel(String place, bool hostel) => hostel && place != 'MSH' ? '$place Hostel' : place;
