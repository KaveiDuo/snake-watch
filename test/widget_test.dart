import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:snake_watch/data/app_state.dart';
import 'package:snake_watch/main.dart';

void main() {
  testWidgets('Sign-in screen shows both sign-in options', (tester) async {
    await tester.pumpWidget(SnakeWatchApp(state: AppState()));
    expect(find.text('Sign in with Outlook'), findsOneWidget);
    expect(find.text('Hostel authority sign-in'), findsOneWidget);
  });

  test('Marking a report safe lowers the open count', () {
    final s = AppState();
    final before = s.hostelOpen;
    s.markSafe(s.hostelReports.firstWhere((r) => !r.safe), true);
    expect(s.hostelOpen, before - 1);
  });

  test('Pins on a hostel or campus building go to its authority; open areas go to nobody', () {
    final s = AppState();
    expect(s.locFromMap(const LatLng(26.19043, 91.70156)).name, 'Kameng Hostel');
    expect(s.locFromMap(const LatLng(26.18574, 91.68935)).name, 'Core 5');
    expect(s.locFromMap(const LatLng(26.19665, 91.69748)).name, 'IITG Hospital');
    expect(s.locFromMap(const LatLng(26.19248, 91.69901)).name, 'New SAC');
    expect(s.locFromMap(const LatLng(26.19580, 91.68998)).name, 'D-type Quarters');
    expect(s.locFromMap(const LatLng(26.19418, 91.69236)).name, 'IIT Guwahati Viewpoint');
    // Coordinates given by the user for KV, the pool and the Central Library
    expect(s.locFromMap(const LatLng(26.184588, 91.696582)).name, 'Kendriya Vidyalaya (KV)');
    expect(s.locFromMap(const LatLng(26.191318, 91.699137)).name, 'Swimming Pool');
    expect(s.locFromMap(const LatLng(26.189272, 91.693006)).name, 'Central Library');
    final field = s.locFromMap(const LatLng(26.19506, 91.70221)); // cricket ground
    expect(field.covered, isFalse);
    expect(field.name, 'Cricket Ground');
  });

  test('Open-area pins are named after the road, field or lake they are on', () {
    final s = AppState();
    expect(s.locFromMap(const LatLng(26.192957, 91.69016)).name, 'Suryamukhi Road');
    expect(s.locFromMap(const LatLng(26.19030, 91.69458)).name, 'IITG Lake');
    expect(s.locFromMap(const LatLng(26.19057, 91.69705)).name, 'Cricket Pitch');
  });

  test("A student's report inside Kameng reaches the Kameng authority's console", () {
    final s = AppState();
    final before = s.hostelOpen;
    s.startDraft(at: s.locFromMap(const LatLng(26.19043, 91.70156)));
    s.setVenom(Venom.venomous);
    final r = s.submit();
    expect(s.hostelReports, contains(r));
    expect(s.hostelOpen, before + 1);
  });
}
