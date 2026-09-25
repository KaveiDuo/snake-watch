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

  test('Taps inside a hostel are covered by that hostel; elsewhere is an open area', () {
    final s = AppState();
    expect(s.locFromMap(const LatLng(26.19043, 91.70156)).name, 'Kameng Hostel');
    expect(s.locFromMap(const LatLng(26.1865, 91.6900)).covered, isFalse);
  });
}
