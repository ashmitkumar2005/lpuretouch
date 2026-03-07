import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/error_retry_widget.dart';
import 'announcements_screen.dart';

const Map<String, IconData> _menuIcons = {
  'Announcements': Icons.campaign_outlined,
  'Attendance': Icons.how_to_reg_outlined,
  'Assignment (CA)': Icons.assignment_outlined,
  'Events': Icons.celebration_outlined,
  'Fee Statement': Icons.receipt_long_outlined,
  'Messages': Icons.message_outlined,
  'Result': Icons.emoji_events_outlined,
  'Seating Plan': Icons.event_seat_outlined,
  'Time table': Icons.calendar_month_outlined,
  'Teacher on Leave': Icons.directions_run_outlined,
  'View Marks': Icons.bar_chart_outlined,
  'Inventory': Icons.inventory_2_outlined,
  'Make Up Adjustment': Icons.autorenew_outlined,
  'Log RMS Request': Icons.add_task_outlined,
  'RMS Request Status': Icons.search_outlined,
  'Placement Drive': Icons.work_outline,
  'Visitor Gate Pass': Icons.confirmation_number_outlined,
  'Doctor Appointment': Icons.local_hospital_outlined,
};

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _user;
  List<dynamic> _menus = [];
  List<dynamic>? _timetable;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer heavy work until AFTER the route entry animation completes.
    // During the 300ms transition only the skeleton is shown — lightweight.
    // Once the screen settles, _load() fires and AnimatedListItem stagger begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(AppDurations.medium, () {
        if (mounted) _load();
      });
    });
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      if (mounted) setState(() { _loading = true; _error = null; });
      final user = await _authService.getUser();
      final menus = await _authService.getMenus();
      final timetable = await _authService.fetchTimetable();
      if (mounted) {
        setState(() {
          _user = user;
          _menus = menus
              .where((m) =>
                  m['MenuText'] != null &&
                  m['RouteName'] != 'OutAppBrowser')
              .toList();
          _timetable = timetable;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
    // Background profile refresh ...
    // Background profile refresh
    _authService.fetchProfile(forceRefresh: forceRefresh).then((_) async {
      final refreshed = await _authService.getUser();
      if (mounted) setState(() => _user = refreshed);
    }).catchError((_) {});
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _load(forceRefresh: true);
  }

  // Filter out redundant items now available in the header
  List<dynamic> get _filtered =>
      _menus.where((item) =>
          item['MenuText'] != 'Announcements' &&
          item['MenuText'] != 'Messages').toList();

  @override
  Widget build(BuildContext context) {
    final name =
        (_user?['ExtractedName'] ?? 'Student').toString().split(' ')[0];
    final regNo = _user?['RegNo'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: _loading
          ? const _DashboardSkeleton()
          : _error != null
              ? ErrorRetryWidget(
                  message: ErrorRetryWidget.friendlyMessage(_error!),
                  onRetry: _load,
                )
              : RefreshIndicator(
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.bgWhite,
              displacement: 60,
              strokeWidth: 2.5,
              onRefresh: _onRefresh,
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH,
                    vertical: AppSpacing.lg,
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top User Profile Header
                      AnimatedListItem(
                        index: 0,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_user != null) {
                                  GlobalLayout.of(context)?.navigateTo(
                                      3, ProfileScreen(user: _user!), '/profile');
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Semantics(
                                button: true,
                                label: 'Open profile',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Step 11: Hero wrapping avatar
                                    Hero(
                                      tag: 'user-avatar',
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryBlue.withValues(alpha: 0.5),
                                              AppColors.primaryBlue.withValues(alpha: 0.1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0] : 'U',
                                                style: AppTextStyles.headline.copyWith(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_user != null) {
                                    GlobalLayout.of(context)?.navigateTo(
                                        3, ProfileScreen(user: _user!), '/profile');
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        'HI, ${name.toUpperCase()}',
                                        style: AppTextStyles.headline.copyWith(
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Text(
                                      regNo,
                                      style: AppTextStyles.footnote,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Messages',
                              child: AppCard(
                                width: 44,
                                height: 44,
                                padding: EdgeInsets.zero,
                                radius: 22,
                                onTap: () {},
                                child: Icon(
                                  Icons.message_outlined,
                                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Semantics(
                              button: true,
                              label: 'Announcements',
                              child: AppCard(
                                width: 44,
                                height: 44,
                                padding: EdgeInsets.zero,
                                radius: 22,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                                  );
                                },
                                child: Icon(
                                  Icons.campaign_outlined,
                                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 2. Main Title (Greeting + LPU TOUCH Logo)
                      AnimatedListItem(
                        index: 1,
                        child: Semantics(
                          header: true,
                          label: 'Welcome to LPU Touch',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome To',
                                style: AppTextStyles.headline.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Text('LPU', style: AppTextStyles.logoLpu.copyWith(fontSize: 22)),
                                  const SizedBox(width: 6),
                                  Text('TOUCH', style: AppTextStyles.logoTouch.copyWith(fontSize: 22)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Today's Timetable (2x4 Grid for up to 8 subjects)
                      AnimatedListItem(
                        index: 2,
                        child: _buildTimetable(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 4. Quick Access Card
                      AnimatedListItem(
                        index: 3,
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Quick Access', style: AppTextStyles.title3),
                                  Icon(Icons.bolt_rounded,
                                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                                      size: 20),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.15,
                                ),
                                itemCount: _filtered.length > 6 ? 6 : _filtered.length,
                                itemBuilder: (context, index) =>
                                    _MenuCard(item: _filtered[index]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.dockBuffer),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Timetable Layout (Neumorphic Soft UI Grid) ─────────────────────────
  Widget _buildTimetable() {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final List<Map<String, String>> todaysTimetable = [];

    if (_timetable != null && _timetable!.isNotEmpty) {
      final String todayName = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
      ][now.weekday - 1];

      // Filter for today's classes
      final List<dynamic> todayClasses = _timetable!.where((t) {
        String rawDay = (t['WeekDay']?.toString() ?? t['Day']?.toString() ?? '').trim();
        
        // Handle numeric days (1=Monday, ..., 7=Sunday)
        final dayMap = {
          "1": "Monday", "2": "Tuesday", "3": "Wednesday",
          "4": "Thursday", "5": "Friday", "6": "Saturday", "7": "Sunday"
        };
        if (dayMap.containsKey(rawDay)) {
          rawDay = dayMap[rawDay]!;
        }
        
        return rawDay.toLowerCase() == todayName.toLowerCase();
      }).toList();

      if (todayClasses.isNotEmpty) {
        for (var t in todayClasses) {
          final String desc = t['Description']?.toString() ?? 'N/A';
          final String time = (t['AttendanceTime']?.toString() ?? 'N/A').trim();
          
          final codeMatch = RegExp(r'C:([^\s/]+)').firstMatch(desc);
          final groupMatch = RegExp(r'G:([^\s/]+)').firstMatch(desc);
          final roomMatch = RegExp(r'R:\s?([^\n/]+)').firstMatch(desc);
          
          String code = codeMatch?.group(1) ?? '';
          String group = groupMatch?.group(1) ?? '';
          String room = roomMatch?.group(1)?.trim() ?? '';
          String type = desc.split('/').first.trim();
          
          if (code.isEmpty) code = type;

          todaysTimetable.add({
            'code': code.toUpperCase(),
            'type': type,
            'group': group,
            'room': room.isNotEmpty ? room : 'Room',
            'time': time,
          });
        }
      } else if (isWeekend) {
        todaysTimetable.addAll(List.generate(8, (_) => {
          'code': '', 'room': 'No class', 'time': '-', 'type': '', 'group': ''
        }));
      } else {
        todaysTimetable.add({
          'code': 'No classes scheduled', 'room': 'Free Day', 'time': '-', 'type': '', 'group': ''
        });
      }
    } else if (isWeekend) {
      todaysTimetable.addAll(List.generate(8, (_) => {
        'code': '', 'room': 'No class', 'time': '-', 'type': '', 'group': ''
      }));
    } else {
      todaysTimetable.addAll(List.generate(8, (_) => {
        'code': '', 'room': 'Loading...', 'time': '-', 'type': '', 'group': ''
      }));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s Timetable', style: AppTextStyles.title3),
                Icon(Icons.calendar_today_rounded, color: AppColors.textPrimary.withValues(alpha: 0.6), size: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.xl, // Increase spacing for Neumorphic shadows
              crossAxisSpacing: AppSpacing.xl,
              mainAxisExtent: 85,
            ),
            itemCount: todaysTimetable.length,
            itemBuilder: (context, i) {
              final t = todaysTimetable[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDashboard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(4, 4),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 15,
                      offset: Offset(-4, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (t['code'] ?? '').toUpperCase(),
                                style: AppTextStyles.headline.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t['room'] ?? 'Room',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF878D96), // Solid equivalent of Primary color @ 0.5 opacity
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrangeGlow.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t['time'] ?? '-',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              color: AppColors.brandOrangeGlow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final dynamic item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.item['MenuText'] as String;
    final icon = _menuIcons[title] ?? Icons.grid_view_rounded;

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          final navCtx = navigatorKey.currentContext;
          if (navCtx != null) {
            ScaffoldMessenger.of(navCtx).showSnackBar(
              SnackBar(
                content: Text('Opening $title...'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppDurations.fast,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.bgDashboard,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(3, 3),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      offset: Offset(-3, -3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title.contains(' ') ? title.split(' ').first : title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Loading ─────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.lg,
            ),
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _ShimmerBox(
                        width: 44, height: 44, borderRadius: AppRadius.pill),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ShimmerBox(width: 100, height: 16, borderRadius: 4),
                          SizedBox(height: 6),
                          _ShimmerBox(width: 140, height: 13, borderRadius: 4),
                        ],
                      ),
                    ),
                    const _ShimmerBox(
                        width: 44, height: 44, borderRadius: AppRadius.pill),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _ShimmerBox(
                    width: 250, height: 32, borderRadius: AppRadius.sm),
                const SizedBox(height: AppSpacing.xxl),
                const _ShimmerBox(
                    width: double.infinity, height: 56, borderRadius: AppRadius.xl),
                const SizedBox(height: AppSpacing.xxl),
                const _ShimmerBox(
                    width: double.infinity, height: 180, borderRadius: AppRadius.xxl),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.grey.withOpacity(0.2), thickness: 1)),
                    const SizedBox(width: AppSpacing.lg),
                    const _ShimmerBox(
                        width: 120, height: 26, borderRadius: AppRadius.pill),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                        child: Divider(
                            color: Colors.grey.withOpacity(0.2), thickness: 1)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _ShimmerBox(
                    width: double.infinity,
                    height: 150,
                    borderRadius: AppRadius.xxl),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _ShimmerBox(
              width: double.infinity, height: 72, borderRadius: 36),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool light;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.light = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _slide =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: const Offset(1.5, 0))
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.light ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10);
    final highlightColor =
        widget.light ? Colors.white.withAlpha(50) : Colors.black.withAlpha(25);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            Container(color: baseColor),
            Positioned.fill(
              child: SlideTransition(
                position: _slide,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        highlightColor,
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
