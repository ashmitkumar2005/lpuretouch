import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import '../services/quick_access_service.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/error_retry_widget.dart';
import 'announcements_screen.dart';
import 'messages_screen.dart';
import '../widgets/liquid_search_overlay.dart';
import '../services/notification_service.dart';

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
  final _quickAccessService = QuickAccessService();
  final _notificationService = NotificationService();
  Map<String, dynamic>? _user;
  List<dynamic> _menus = [];
  List<dynamic>? _timetable;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    // Defer heavy work until AFTER the route entry animation completes.
    // During the 300ms transition only the skeleton is shown — lightweight.
    // Once the screen settles, _load() fires and AnimatedListItem stagger begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickAccessService.init();
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

  // Filter based on user selection in QuickAccessService
  List<dynamic> _getFilteredItems(List<dynamic> menus, List<String> selected) {
    if (selected.isEmpty) {
      return menus.where((item) =>
          item['MenuText'] != 'Announcements' &&
          item['MenuText'] != 'Messages').take(6).toList();
    }
    
    // Sort and filter based on selection
    final List<dynamic> filtered = [];
    for (var title in selected) {
      final match = menus.firstWhere(
        (m) => m['MenuText'] == title, 
        orElse: () => null
      );
      if (match != null) filtered.add(match);
    }
    return filtered;
  }

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
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Row(
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
                                                color: AppColors.bgDashboard,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.25),
                                                    blurRadius: 20,
                                                    offset: const Offset(10, 10),
                                                  ),
                                                  const BoxShadow(
                                                    color: Colors.white,
                                                    blurRadius: 20,
                                                    offset: Offset(-10, -10),
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
                                // Spacing for the search button which is positioned as overlay
                                const SizedBox(width: 44 + AppSpacing.md),
                                // Messages Button with Notification Dot
                                ValueListenableBuilder<bool>(
                                  valueListenable: _notificationService.hasUnreadMessages,
                                  builder: (context, hasUnread, _) {
                                    return Stack(
                                      children: [
                                        _CircleButton(
                                          icon: Icons.chat_bubble_outline_rounded,
                                          label: 'Messages',
                                          onTap: () async {
                                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
                                            _notificationService.refresh();
                                          },
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.bgDashboard, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: AppSpacing.md),
                                // Announcements Button with Notification Dot
                                ValueListenableBuilder<bool>(
                                  valueListenable: _notificationService.hasUnreadAnnouncements,
                                  builder: (context, hasUnread, _) {
                                    return Stack(
                                      children: [
                                        _CircleButton(
                                          icon: Icons.campaign_outlined,
                                          label: 'Announcements',
                                          onTap: () async {
                                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
                                            _notificationService.refresh();
                                          },
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.bgDashboard, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            // Liquid Search Drop Button
                            Positioned(
                              right: 44 * 2 + AppSpacing.md * 2,
                              child: _LiquidSearchButton(
                                onOpen: (origin) {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (context, _, __) => LiquidSearchOverlay(
                                        origin: origin,
                                        menus: _menus,
                                        onItemSelected: (item) {
                                          final title = item['MenuText'];
                                          if (title == 'Announcements') {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
                                          } else if (title == 'Messages') {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Opening $title...'),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
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
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.bgDashboard,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 30,
                                offset: const Offset(14, 14),
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 30,
                                offset: Offset(-14, -14),
                              ),
                            ],
                          ),
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
                              ValueListenableBuilder<List<String>>(
                                valueListenable: _quickAccessService.selectedItemsNotifier,
                                builder: (context, selected, _) {
                                  final items = _getFilteredItems(_menus, selected);
                                  return GridView.builder(
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
                                    itemCount: items.length,
                                    itemBuilder: (context, index) =>
                                        _MenuCard(item: items[index]),
                                  );
                                },
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
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(14, 14),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 30,
                      offset: Offset(-14, -14),
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
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(10, 10),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 20,
                      offset: Offset(-10, -10),
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
                // 1. Header Skeleton
                Row(
                  children: [
                    ShimmerLoading.circle(size: 50), // Avatar
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(width: 80, height: 18, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerLoading(width: 120, height: 12, borderRadius: 4),
                      ],
                    ),
                    const Spacer(),
                    ShimmerLoading.circle(size: 44), // Messages
                    const SizedBox(width: AppSpacing.md),
                    ShimmerLoading.circle(size: 44), // Announcements
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // 2. Greeting
                ShimmerLoading(width: 100, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerLoading(width: 180, height: 24, borderRadius: 4),
                const SizedBox(height: AppSpacing.lg),

                // 3. Timetable Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerLoading(width: 150, height: 20, borderRadius: 4),
                    ShimmerLoading.circle(size: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Timetable Grid (2x4)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.xl,
                    crossAxisSpacing: AppSpacing.xl,
                    mainAxisExtent: 85,
                  ),
                  itemCount: 8,
                  itemBuilder: (_, __) => const ShimmerLoading(
                      width: double.infinity, height: 85, borderRadius: AppRadius.lg),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 4. Quick Access Card
                const ShimmerLoading(
                  width: double.infinity,
                  height: 180,
                  borderRadius: AppRadius.lg,
                ),
                const SizedBox(height: AppSpacing.dockBuffer),
              ],
            ),
          ),
        ),
        // 5. Floating Dock Skeleton
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Center(
            child: ShimmerLoading(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 64,
              borderRadius: 32,
            ),
          ),
        ),
      ],
    );
  }
}



class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.bgDashboard,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(10, 10),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 20,
                offset: Offset(-10, -10),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _LiquidSearchButton extends StatelessWidget {
  final Function(Offset) onOpen;

  const _LiquidSearchButton({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final renderContent = context.findRenderObject() as RenderBox;
        final position = renderContent.localToGlobal(Offset.zero);
        final center = position + Offset(renderContent.size.width / 2, renderContent.size.height / 2);
        onOpen(center);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(10, 10),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              offset: Offset(-10, -10),
            ),
          ],
        ),
        child: const Icon(
          Icons.search_rounded,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}
