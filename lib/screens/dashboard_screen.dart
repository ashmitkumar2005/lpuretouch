import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

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
    final name = (_user?['ExtractedName'] ?? 'Student').toString().split(' ')[0];
    final regNo = _user?['RegNo'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Whitesmoke
      body: _loading
          ? const _DashboardSkeleton()
          : Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top User Profile Section
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF2050E4),
                              child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('HI, $name', style: const TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.bold)),
                                  const Text('Storage Used: 75%', style: TextStyle(color: Color(0xFF9D9D9D), fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF000000)),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // 2. Main Title Area
                        const Text(
                          'Welcome to LPU Touch',
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search files',
                              hintStyle: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500, fontSize: 15),
                              prefixIcon: Padding( // Mocking the grey dot from reference
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  decoration: const BoxDecoration(color: Color(0xFF9D9D9D), shape: BoxShape.circle),
                                  width: 8, height: 8,
                                ),
                              ),
                              suffixIcon: const Icon(Icons.tune_rounded, color: Color(0xFF9D9D9D), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 4. Recent Files & Folders Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC0A9FE), // Soft purple matching mockup
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recent Files & Folders', style: TextStyle(color: Color(0xFF000000), fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF000000)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildShortcutItem(Icons.folder_copy_rounded, Colors.orangeAccent, 'My Backup', '50.5 GB'),
                                  _buildShortcutItem(Icons.videocam_rounded, const Color(0xFF2050E4), 'Videos', '10.5 GB'),
                                  _buildShortcutItem(Icons.description_rounded, Colors.redAccent, 'Projects Files', '600 KB'),
                                  _buildShortcutItem(Icons.folder_rounded, Colors.amber, 'Photos', '12.5 GB'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 5. Splitter Line
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                              ),
                              child: const Text('420 Files • 6 Folder', style: TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 6. Viewed Links Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE68C), // Soft yellow matching mockup
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Viewed Links', style: TextStyle(color: Color(0xFF000000), fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  const SizedBox(
                                    width: 200,
                                    child: Text("Links you've previously\nviewed show up here.", 
                                      style: TextStyle(color: Color(0xFF444444), fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        const Expanded(child: Text('See All', style: TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.w600))),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(color: Color(0xFF000000), shape: BoxShape.circle),
                                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // (Placeholder for illustration on right)
                            ],
                          ),
                        ),
                        const SizedBox(height: 120), // Bottom padding for floating nav
                      ],
                    ),
                  ),
                ),
                // 7. Floating Bottom Nav Bar
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000), // Black
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.home_rounded, color: Color(0xFF000000), size: 26),
                        ),
                        const Icon(Icons.folder_open_rounded, color: Colors.white, size: 26),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: Color(0xFF2050E4), shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        ),
                        const Icon(Icons.image_outlined, color: Colors.white, size: 26),
                        GestureDetector(
                          onTap: () {
                            if (_user != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen(user: _user!)),
                              );
                            }
                          },
                          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShortcutItem(IconData iconData, Color iconColor, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Color(0xFF000000), fontSize: 12, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
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
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Profile Skeleton
                Row(
                  children: [
                    const _ShimmerBox(width: 44, height: 44, borderRadius: 22),
                    const SizedBox(width: 12),
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
                    const _ShimmerBox(width: 44, height: 44, borderRadius: 22),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Title Area Skeleton
                const _ShimmerBox(width: 250, height: 32, borderRadius: 8),
                const SizedBox(height: 24),

                // 3. Search Bar Skeleton
                const _ShimmerBox(width: double.infinity, height: 56, borderRadius: 30),
                const SizedBox(height: 28),

                // 4. Primary Card Skeleton
                const _ShimmerBox(width: double.infinity, height: 180, borderRadius: 24),
                const SizedBox(height: 24),

                // 5. Splitter Line Skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Expanded(child: _ShimmerBox(width: double.infinity, height: 1, borderRadius: 0)),
                    SizedBox(width: 12),
                    _ShimmerBox(width: 120, height: 26, borderRadius: 13),
                    SizedBox(width: 12),
                    Expanded(child: _ShimmerBox(width: double.infinity, height: 1, borderRadius: 0)),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. Secondary Card Skeleton
                const _ShimmerBox(width: double.infinity, height: 220, borderRadius: 24),
                
                const SizedBox(height: 120), // Bottom padding
              ],
            ),
          ),
        ),
        // 7. Floating Nav Skeleton
        const Positioned(
          bottom: 24, left: 24, right: 24,
          child: _ShimmerBox(width: double.infinity, height: 72, borderRadius: 36),
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

