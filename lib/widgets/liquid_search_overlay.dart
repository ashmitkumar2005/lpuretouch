import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';

class LiquidSearchOverlay extends StatefulWidget {
  final Offset origin;
  final List<dynamic> menus;
  final Function(dynamic) onItemSelected;

  const LiquidSearchOverlay({
    super.key,
    required this.origin,
    required this.menus,
    required this.onItemSelected,
  });

  @override
  State<LiquidSearchOverlay> createState() => _LiquidSearchOverlayState();
}

class _LiquidSearchOverlayState extends State<LiquidSearchOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _results = [];
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );
    _controller.forward();
    _focusNode.requestFocus();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final filtered = widget.menus.where((m) {
      final text = (m['MenuText'] ?? '').toString().toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();
    setState(() => _results = filtered);
  }

  void _close() async {
    if (_isClosing) return;
    _isClosing = true;
    _focusNode.unfocus();
    await _controller.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _close();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Liquid Expansion
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiquidPainter(
                    origin: widget.origin,
                    radiusPercent: _animation.value,
                    color: AppColors.bgDashboard,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            
            // Content
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgDashboard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(6, 6),
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 12,
                              offset: Offset(-6, -6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: AppColors.textTertiary.withValues(alpha: 0.7), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search for features...',
                                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary.withValues(alpha: 0.6)),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                ),
                                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Results
                      Expanded(
                        child: _results.isEmpty && _searchController.text.isNotEmpty
                            ? Center(
                                child: Text(
                                  'No results found',
                                  style: AppTextStyles.subhead.copyWith(color: AppColors.textTertiary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  final title = (item['MenuText'] ?? '').toString();
                                  
                                  String category = "Explore";
                                  if (title.contains('Fee') || title.contains('Marks')) category = "Accounts";
                                  if (title.contains('Time') || title.contains('Attendance')) category = "Academic";
                                  if (title.contains('Drive') || title.contains('Placement')) category = "Career";

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: InkWell(
                                      onTap: () {
                                        widget.onItemSelected(item);
                                        _close();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.lg),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgDashboard,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(4, 4),
                                            ),
                                            const BoxShadow(
                                              color: Colors.white,
                                              blurRadius: 10,
                                              offset: Offset(-4, -4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.toUpperCase(),
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    title,
                                                    style: AppTextStyles.subhead.copyWith(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.north_west_rounded, size: 14, color: AppColors.textTertiary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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

class _LiquidPainter extends CustomPainter {
  final Offset origin;
  final double radiusPercent;
  final Color color;

  _LiquidPainter({
    required this.origin,
    required this.radiusPercent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate max radius to cover the screen
    final double maxRadius = _calculateMaxRadius(origin, size);
    final double currentRadius = maxRadius * radiusPercent;

    canvas.drawCircle(origin, currentRadius, paint);
  }

  double _calculateMaxRadius(Offset origin, Size size) {
    final double dx = max(origin.dx, size.width - origin.dx);
    final double dy = max(origin.dy, size.height - origin.dy);
    return sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) {
    return oldDelegate.radiusPercent != radiusPercent || oldDelegate.origin != origin;
  }
}
