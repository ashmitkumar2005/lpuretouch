import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/app_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';
import '../core/theme/app_text_styles.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _service = AttendanceService(AuthService());
  List<dynamic>? _attendanceData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchAttendance();
      // Inspecting data to build UI
      print('Attendance Data: $data');
      
      setState(() {
        final List<dynamic> list = (data is List) ? data : (data['data'] ?? []);
        // Sort from low to high percentage
        list.sort((a, b) {
          final aVal = double.tryParse(a['Total_Perc']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0;
          final bVal = double.tryParse(b['Total_Perc']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0;
          return aVal.compareTo(bVal);
        });
        _attendanceData = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Center(
                child: Text(
                  'Attendance',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _AttendanceSkeleton();
    }

    if (_error != null) {
      return Center(
        child: ErrorRetryWidget(
          message: _error!,
          onRetry: _fetchData,
        ),
      );
    }

    if (_attendanceData == null || _attendanceData!.isEmpty) {
      return Center(
        child: Text(
          'No attendance data available yet.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Attempt to calculate overall attendance
    double totalPercent = 0.0;
    int subjectsCount = 0;
    for (var item in _attendanceData!) {
       final percentStr = item['Total_Perc']?.toString() ?? '0';
       final percentVal = double.tryParse(percentStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
       if (percentVal > 0) {
         totalPercent += percentVal;
         subjectsCount++;
       }
    }
    // UMS sometimes returns Aggregate inside the first item as 'Total'
    double avgPercent = subjectsCount > 0 ? (totalPercent / subjectsCount) : 0.0;
    if (_attendanceData!.isNotEmpty && _attendanceData![0]['Total'] != null) {
      final tStr = _attendanceData![0]['Total'].toString();
      avgPercent = double.tryParse(tStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? avgPercent;
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: _buildOverallCard(avgPercent),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.dockBuffer + AppSpacing.xl,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _attendanceData![index];
                  return _buildSubjectCard(item, index + 1);
                },
                childCount: _attendanceData!.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(double avgPercent) {
    return AnimatedListItem(
      index: 0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 32,
              offset: const Offset(12, 12),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 32,
              offset: Offset(-12, -12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Attendance',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep it above 75%!',
                  style: AppTextStyles.footnote,
                ),
              ],
            ),
            _buildCircularPercentage(avgPercent, size: 80, strokeWidth: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(dynamic item, int index) {
    final title = item['CourseCode'] ?? 'Unknown Subject';
    final faculty = item['Faculty'] ?? 'Unknown Faculty';
    final attended = item['Total_Attd']?.toString() ?? '0';
    final delivered = item['Total_Delv']?.toString() ?? '0';
    final rollNo = item['RollNumber']?.toString() ?? '';

    return AnimatedListItem(
      index: index,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCircularPercentage(double.tryParse(item['Total_Perc']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0.0, size: 54, strokeWidth: 5),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
             Text(
              faculty,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (rollNo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Roll: $rollNo',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$attended / $delivered',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularPercentage(double percent, {required double size, required double strokeWidth}) {
    Color progressColor = AppColors.primaryBlue;
    if (percent >= 80) {
      progressColor = Colors.green.shade600;
    } else if (percent >= 75) {
      progressColor = Colors.orange.shade400; // Yellowish-orange for 75-79
    } else {
      progressColor = Colors.red.shade500;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgDashboard,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent, // Clean neumorphic look
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${percent.toInt()}%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Overall Card Skeleton
          ShimmerLoading.card(height: 120),
          const SizedBox(height: AppSpacing.xl),
          // Grid Skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppRadius.md,
            ),
          ),
        ],
      ),
    );
  }
}
