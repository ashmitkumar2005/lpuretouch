import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';
import '../services/notification_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _authService = AuthService();
  List<dynamic>? _allAnnouncements;
  List<dynamic>? _announcements;
  bool _loading = true;
  String? _error;

  final int _pageSize = 10;
  int _currentLimit = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (mounted) setState(() { _loading = true; _error = null; });
      final data = await _authService.fetchAnnouncements();
      if (mounted) {
        setState(() {
          _allAnnouncements = data;
          _currentLimit = _pageSize;
          _announcements = _allAnnouncements?.take(_currentLimit).toList();
          _loading = false;
        });
        if (data != null && data.isNotEmpty) {
          NotificationService().markAnnouncementsAsSeen(data);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_allAnnouncements == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentLimit = (_currentLimit + _pageSize).clamp(0, _allAnnouncements!.length);
      _announcements = _allAnnouncements!.take(_currentLimit).toList();
    });
  }

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('examination') || c.contains('exam')) {
      return Colors.purpleAccent.shade400.withOpacity(0.85);
    } else if (c.contains('academic')) {
      return Colors.lightBlue.shade600.withOpacity(0.85);
    } else if (c.contains('placement')) {
      return Colors.indigoAccent.shade400.withOpacity(0.85);
    } else if (c.contains('sports') || c.contains('culture') || c.contains('co-curricular') || c.contains('event')) {
      return Colors.orange.shade700.withOpacity(0.85);
    } else if (c.contains('admin') || c.contains('misc')) {
      return Colors.pink.shade500.withOpacity(0.85);
    } else if (c.contains('hostel')) {
      return Colors.brown.shade400.withOpacity(0.85);
    } else if (c.contains('discipline')) {
      return Colors.redAccent.shade400.withOpacity(0.85);
    } else if (c.contains('general')) {
      return Colors.teal.shade500.withOpacity(0.85);
    }
    return Colors.blueGrey.shade500.withOpacity(0.85);
  }

  /// Extracts LPU ref code like (LPU/10.2/ANN...) from the end of [subject].
  /// Returns `(cleanTitle, refCode?)`.
  (String, String?) _parseSubject(String subject) {
    final regex = RegExp(r'\(\s*LPU/.*?\s*\)$');
    final match = regex.firstMatch(subject);
    if (match != null) {
      final clean = subject.substring(0, match.start).trim();
      final ref = match.group(0)!.replaceAll(RegExp(r'^\(\s*|\s*\)$'), '').trim();
      return (clean, ref);
    }
    return (subject, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.bgDashboard,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 28,
                            offset: const Offset(10, 10),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 28,
                            offset: Offset(-10, -10),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Announcements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: _loading
          ? const _AnnouncementsSkeleton()
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
              : (_announcements == null || _announcements!.isEmpty)
                  ? Center(
                      child: Text(
                        'No announcements found.',
                        style: AppTextStyles.subhead.copyWith(color: AppColors.textTertiary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.bgWhite,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, AppSpacing.screenH),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemCount: _announcements!.length + 1,
                        itemBuilder: (context, index) {
                          // ── Load More / End Footer ──────────────────────
                          if (index == _announcements!.length) {
                            final hasMore = _currentLimit < (_allAnnouncements?.length ?? 0);
                            return Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
                              child: Center(
                                child: hasMore
                                    ? _NeumorphicLoadMoreButton(onTap: _loadMore)
                                    : Text(
                                        '— No more messages —',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Text',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textTertiary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            );
                          }

                          // ── Announcement Card ───────────────────────────
                          final item = _announcements![index];
                          final rawSubject = (item['Subject'] ?? item['Title'] ?? 'Announcement').toString();
                          final (cleanTitle, refCode) = _parseSubject(rawSubject);
                          final rawDate = (item['EntryDate'] ?? item['Date'] ?? '').toString();
                          final category = (item['Category'] ?? item['Type'] ?? 'General').toString();
                          final description = (item['Description'] ?? '').toString();
                          final catColor = _getCategoryColor(category);

                          return AnimatedListItem(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.bgDashboard,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 30,
                                      offset: const Offset(10, 10),
                                    ),
                                    const BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 30,
                                      offset: Offset(-10, -10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(10, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row: Category Badge + Date
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: catColor,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              fontFamily: 'SF Pro Text',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          rawDate,
                                          style: const TextStyle(
                                            fontFamily: 'SF Pro Text',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    // Main Title
                                    Text(
                                      cleanTitle,
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Text',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    // Description
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontFamily: 'SF Pro Text',
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                          height: 1.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    // LPU Ref Code Pill
                                    if (refCode != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.8),
                                        ),
                                        child: Text(
                                          refCode,
                                          style: const TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 10,
                                            color: AppColors.textTertiary,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Neumorphic Load More Button ───────────────────────────────────────────────
class _NeumorphicLoadMoreButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NeumorphicLoadMoreButton({required this.onTap});

  @override
  State<_NeumorphicLoadMoreButton> createState() => _NeumorphicLoadMoreButtonState();
}

class _NeumorphicLoadMoreButtonState extends State<_NeumorphicLoadMoreButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(10, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 28,
                    offset: const Offset(10, 10),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 28,
                    offset: Offset(-10, -10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Load More',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsSkeleton extends StatelessWidget {
  const _AnnouncementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.bgDashboard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-5, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(width: 60, height: 18, borderRadius: 6), // Category
                  const Spacer(),
                  const ShimmerLoading(width: 80, height: 14, borderRadius: 4), // Date
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const ShimmerLoading(width: 220, height: 18, borderRadius: 4), // Title
              const SizedBox(height: 8),
              const ShimmerLoading(width: double.infinity, height: 14, borderRadius: 4), // Desc line 1
              const SizedBox(height: 4),
              const ShimmerLoading(width: 180, height: 14, borderRadius: 4), // Desc line 2
            ],
          ),
        ),
      ),
    );
  }
}
