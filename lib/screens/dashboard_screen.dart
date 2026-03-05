import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
        _menus = menus.where((m) => m['MenuText'] != null && m['RouteName'] != 'OutAppBrowser').toList();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _menus
      : _menus.where((m) => m['MenuText'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final name = (_user?['Name'] ?? 'Student').toString().split(' ')[0];
    final regNo = _user?['RegNo'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: _loading
          ? const _DashboardSkeleton()
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D1B2A), Color(0xFF1A2F4A)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Welcome back 👋', style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                    if (regNo.isNotEmpty)
                                      Text(regNo, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, fontFamily: 'monospace')),
                                  ],
                                ),
                                IconButton(
                                  onPressed: _logout,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                                  tooltip: 'Sign Out',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search features...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
                                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.35), size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Feature count
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text('${_filtered.length} features available',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),

                // Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _MenuCard(item: _filtered[index]),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...'), duration: const Duration(seconds: 1)),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF26522).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFF26522), size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2D3748), height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Premium Skeleton Loading UX
// ══════════════════════════════════════════════════════════════
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Header Skeleton
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B2A), Color(0xFF1A2F4A)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBox(width: 100, height: 14, borderRadius: 4, light: true),
                            const SizedBox(height: 8),
                            _ShimmerBox(width: 160, height: 26, borderRadius: 6, light: true),
                            const SizedBox(height: 8),
                            _ShimmerBox(width: 80, height: 12, borderRadius: 4, light: true),
                          ],
                        ),
                        _ShimmerBox(width: 44, height: 44, borderRadius: 12, light: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar skeleton
                    _ShimmerBox(width: double.infinity, height: 52, borderRadius: 14, light: true),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Feature count skeleton
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ShimmerBox(width: 120, height: 14, borderRadius: 4),
          ),
        ),

        // Grid skeleton (show 12 items as placeholder)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 18),
              childCount: 15,
            ),
          ),
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

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _slide = Tween<Offset>(begin: const Offset(-1.5, 0), end: const Offset(1.5, 0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solid base color
    final baseColor = widget.light ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10);
    // Gradient highlight color
    final highlightColor = widget.light ? Colors.white.withAlpha(50) : Colors.black.withAlpha(25);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Static Base Layer
            Container(color: baseColor),
            // GPU-Accelerated Sliding Highlight (0 repaints)
            Positioned.fill(
              child: SlideTransition(
                position: _slide,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0.0, 0.5, 1.0],
                      colors: [Colors.transparent, highlightColor, Colors.transparent],
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

