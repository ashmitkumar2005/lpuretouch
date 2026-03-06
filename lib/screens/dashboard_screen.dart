import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_list_item.dart';

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
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _authService.getUser();
    final menus = await _authService.getMenus();
    if (mounted) {
      setState(() {
        _user = user;
        _menus = menus
            .where((m) =>
                m['MenuText'] != null &&
                m['RouteName'] != 'OutAppBrowser')
            .toList();
        _loading = false;
      });
    }
    // Background profile refresh
    _authService.fetchProfile().then((_) async {
      final refreshed = await _authService.getUser();
      if (mounted) setState(() => _user = refreshed);
    }).catchError((_) {});
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _load();
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _menus
      : _menus
          .where((m) => m['MenuText']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final name =
        (_user?['ExtractedName'] ?? 'Student').toString().split(' ')[0];
    final regNo = _user?['RegNo'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: _loading
          ? const _DashboardSkeleton()
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
                                      4, ProfileScreen(user: _user!), '/profile');
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
                                      child: Material(
                                        color: Colors.transparent,
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.primaryBlue,
                                                  AppColors.primaryBlueLt,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              border: Border.all(
                                                color: AppColors.primaryBlue.withOpacity(0.15),
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryBlue.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0] : 'U',
                                                style: AppTextStyles.headline
                                                    .copyWith(color: Colors.white),
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
                                        4, ProfileScreen(user: _user!), '/profile');
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
                            // Notification button — 48x48 touch target
                            Semantics(
                              button: true,
                              label: 'Notifications',
                              child: SizedBox(
                                width: AppSpacing.massive,
                                height: AppSpacing.massive,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.bgWhite,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.cardSoft,
                                  ),
                                  child: Tooltip(
                                    message: 'Notifications',
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.notifications_none_rounded,
                                        color: AppColors.textPrimary.withOpacity(0.7),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // 2. Main Title
                      AnimatedListItem(
                        index: 1,
                        child: Semantics(
                          header: true,
                          child: const Text(
                            'Welcome to\nLPU Touch',
                            style: AppTextStyles.largeTitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 3. Search Bar (glass card)
                      AnimatedListItem(
                        index: 2,
                        child: AppCard(
                          isGlass: true,
                          padding: EdgeInsets.zero,
                          child: TextField(
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search menus...',
                              hintStyle: AppTextStyles.subhead,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.searchHint,
                                    shape: BoxShape.circle,
                                  ),
                                  width: AppSpacing.sm,
                                  height: AppSpacing.sm,
                                ),
                              ),
                              suffixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.searchHint,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 4. Hero Card — subtle blue gradient
                      AnimatedListItem(
                        index: 3,
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recent Files & Folders',
                                      style: AppTextStyles.title3),
                                  Icon(Icons.format_list_bulleted_rounded,
                                      color: AppColors.textPrimary, size: 22),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildShortcutItem(
                                      Icons.folder_copy_rounded,
                                      Colors.orangeAccent,
                                      'My Backup',
                                      '50.5 GB'),
                                  _buildShortcutItem(
                                      Icons.videocam_rounded,
                                      AppColors.primaryBlue,
                                      'Videos',
                                      '10.5 GB'),
                                  _buildShortcutItem(
                                      Icons.description_rounded,
                                      Colors.redAccent,
                                      'Projects',
                                      '600 KB'),
                                  _buildShortcutItem(
                                      Icons.folder_rounded,
                                      Colors.amber,
                                      'Photos',
                                      '12.5 GB'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 5. Splitter
                      AnimatedListItem(
                        index: 4,
                        child: Row(
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: AppColors.divider, thickness: 1)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm - 2),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.bgDashboard,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                    color: AppColors.divider, width: 1),
                              ),
                              child: Text('420 Files • 6 Folder',
                                  style: AppTextStyles.caption),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: AppColors.divider, thickness: 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 6. Viewed Links Card — replaced yellow with subtle blue
                      AnimatedListItem(
                        index: 5,
                        child: AppCard(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            AppSpacing.xxl,
                            AppSpacing.xxl,
                            AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Viewed Links',
                                  style: AppTextStyles.title3),
                              const SizedBox(height: AppSpacing.xxl),
                              // Empty state
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      size: AppSpacing.massive,
                                      color: AppColors.textTertiary
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'No recent links',
                                      style: AppTextStyles.footnote,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // 7. Quick Activities
                      AnimatedListItem(
                        index: 6,
                        child: Text('Quick Activities', style: AppTextStyles.title3),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedListItem(
                        index: 7,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.lg,
                            mainAxisSpacing: AppSpacing.lg,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _MenuCard(item: _filtered[index]),
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

  Widget _buildShortcutItem(
      IconData iconData, Color iconColor, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, AppSpacing.sm),
              ),
            ],
          ),
          child: Icon(iconData, color: iconColor, size: 26),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyles.caption),
      ],
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
          scale: _pressed ? 0.94 : 1.0,
          duration: AppDurations.fast,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppSpacing.massive,
                  height: AppSpacing.massive,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
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
