import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'profile.dart';
import 'sighting_detail.dart';

/// Hostel authority console: only this hostel's reports. "Mark area safe"
/// removes the pin for every student; "Reopen report" undoes it. The badge
/// counts open reports and filters the list when tapped.
class AuthorityConsole extends StatelessWidget {
  const AuthorityConsole({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final all = s.hostelReports;
    final shown = s.filterOpenOnly ? all.where((r) => !r.safe).toList() : all;
    return DarkPage(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthorityProfile())),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset('assets/images/avatar_authority.jpg', width: 44, height: 44, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.authorityHostel, style: ft(19, w: 700)),
                          Text('Dr. P. Saikia · Hostel authority', style: ft(12, color: C.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: s.toggleFilter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: s.filterOpenOnly ? C.red : C.redSoft, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${s.hostelOpen} OPEN', style: ft(11, w: 800, color: s.filterOpenOnly ? Colors.white : C.redText, ls: 0.5)),
                          if (s.filterOpenOnly) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (s.filterOpenOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 10),
                    child: Text('Showing open reports only · tap the badge to show all', style: ft(12, color: C.muted)),
                  ),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_outlined, color: C.green, size: 48),
                        const SizedBox(height: 12),
                        Text('All clear', style: ft(20, w: 700)),
                        const SizedBox(height: 4),
                        Text('No open reports for ${s.authorityHostel}.', style: ft(13.5, color: C.muted)),
                      ],
                    ),
                  ),
                for (final r in shown)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _ReportCard(r)),
                  ),
                Text(
                  'You only see reports for ${s.authorityHostel}. Other hostels and buildings go to their own authority. '
                  'Marking an area safe removes the pin for every student and notifies the person who reported it.',
                  style: ft(11.5, color: C.faint, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report r;
  const _ReportCard(this.r);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    return Panel(
      border: r.safe ? const Color(0xFF22392A) : C.line2,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SightingDetailScreen(report: r))),
            child: Row(
              children: [
                SnakeThumb(r, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tag.forReport(r),
                      const SizedBox(height: 5),
                      Text(r.title, style: ft(17, w: 700)),
                      Text(r.where, style: ft(12.5, color: const Color(0xFFB0B0B0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text('“${r.note}”', style: ft(13.5, color: const Color(0xFFDCDCDC), height: 1.45)),
          ],
          const SizedBox(height: 7),
          Text('Reported by ${r.reporter} · ${ago(r.time)}', style: ft(12, color: const Color(0xFF7A7A7A))),
          if (r.safe) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_rounded, size: 15, color: C.greenText),
                const SizedBox(width: 6),
                Text('Marked safe — students notified', style: ft(12.5, w: 600, color: C.greenText)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: r.safe
                    ? Btn('Reopen report', kind: BtnKind.ghost, icon: Icons.replay_rounded, height: 50, onTap: () => s.markSafe(r, false))
                    : Btn(
                        'Mark area safe',
                        height: 50,
                        onTap: () {
                          s.markSafe(r, true);
                          toast(context, '${r.title} marked safe · students notified');
                        },
                      ),
              ),
              const SizedBox(width: 9),
              Material(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SightingDetailScreen(report: r))),
                  child: const SizedBox(width: 56, height: 50, child: Icon(Icons.location_on_outlined, color: C.sub)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthorityProfile extends StatelessWidget {
  const AuthorityProfile({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget stat(String v, String l, Color c) => Expanded(
      child: Column(
        children: [
          Text(v, style: ft(22, w: 700, color: c)),
          const SizedBox(height: 4),
          Text(
            l,
            style: ft(12, color: C.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return DarkPage(
      header: const AppHeader('Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        children: [
          IdCard(
            avatar: ClipOval(child: Image.asset('assets/images/avatar_authority.jpg', width: 88, height: 88, fit: BoxFit.cover)),
            name: 'Dr. P. Saikia',
            lines: ['Hostel authority · ${s.authorityHostel}'],
          ),
          const SizedBox(height: 22),
          Text('Snake Watch · ${s.authorityHostel}', style: ft(17, w: 600)),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                stat('${s.hostelOpen}', 'Open now', C.redText),
                Container(width: 1, height: 40, color: C.line),
                stat('${s.safeThisWeek}', 'Marked safe this week', C.green),
                Container(width: 1, height: 40, color: C.line),
                stat('12 min', 'Avg. response', C.text),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Details', style: ft(17, w: 600)),
          const SizedBox(height: 12),
          InfoCard([
            InfoRow(
              Icons.call_outlined,
              'Registered phone',
              '+91 98765 43210',
              editable: false,
              trailing: const Tag('VERIFIED', fg: C.green, bg: C.greenSoft),
            ),
            const InfoRow(Icons.person_outline_rounded, 'Role', 'Hostel authority', editable: false),
            InfoRow(Icons.apartment_outlined, 'Hostel', s.authorityHostel.replaceAll(' Hostel', ''), editable: false),
            const InfoRow(Icons.apartment_outlined, 'Office', 'Kameng Hostel · Ground floor'),
          ]),
          const SizedBox(height: 22),
          const ProfileActions(),
        ],
      ),
    );
  }
}
