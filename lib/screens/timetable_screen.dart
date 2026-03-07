import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _authService = AuthService();
  List<dynamic>? _timetable;
  bool _loading = true;
  int _selectedDayIndex = 0;
  String? _error;

  final List<String> _weekDays = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  final List<String> _shortDays = [
    "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize to current day (1=Mon, ..., 7=Sun)
    final now = DateTime.now();
    _selectedDayIndex = now.weekday - 1;
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      if (mounted) setState(() { _loading = true; _error = null; });
      // If we are forcing refresh, we should also validate the session
      if (forceRefresh) {
        await _authService.validateSession();
      }
      final timetable = await _authService.fetchTimetable();
      if (mounted) {
        setState(() {
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
  }

  Map<String, List<Map<String, String>>> _groupTimetable() {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var day in _weekDays) {
      grouped[day] = [];
    }

    if (_timetable != null) {
      print('[TIMETABLE_SCREEN] Grouping ${_timetable!.length} items');
      for (var t in _timetable!) {
        String rawDay = (t['WeekDay']?.toString() ?? t['Day']?.toString() ?? '').trim();
        
        // Handle numeric days (1=Monday, ..., 7=Sunday)
        final dayMap = {
          "1": "Monday", "2": "Tuesday", "3": "Wednesday",
          "4": "Thursday", "5": "Friday", "6": "Saturday", "7": "Sunday"
        };
        if (dayMap.containsKey(rawDay)) {
          rawDay = dayMap[rawDay]!;
        }

        // Normalize day string (e.g., "MONDAY" or "monday" -> "Monday")
        String day = '';
        if (rawDay.isNotEmpty) {
           day = rawDay[0].toUpperCase() + rawDay.substring(1).toLowerCase();
        }

        if (grouped.containsKey(day)) {
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

          grouped[day]!.add({
            'code': code.toUpperCase(),
            'type': type,
            'group': group,
            'room': room.isNotEmpty ? room : 'Room',
            'time': time,
          });
        } else if (rawDay.isNotEmpty) {
          print('[TIMETABLE_SCREEN] Unmatched day: "$rawDay" (normalized as "$day")');
        }
      }
    } else {
      print('[TIMETABLE_SCREEN] Timetable data is NULL');
    }
    return grouped;
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _load(forceRefresh: true);
  }

  Widget _buildDaySelector() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        physics: const BouncingScrollPhysics(),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDayIndex = index);
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                width: 50,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : AppColors.bgDashboard,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 8,
                          offset: Offset(-2, -2),
                        ),
                      ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortDays[index],
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.textTertiary,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupTimetable();
    final selectedDay = _weekDays[_selectedDayIndex];
    final classes = groupedData[selectedDay] ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      appBar: AppBar(
        title: const Text('Weekly Schedule', style: AppTextStyles.navBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.xl,
                crossAxisSpacing: AppSpacing.xl,
                mainAxisExtent: 110,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => ShimmerLoading.card(height: 110),
            )
          : _error != null
              ? ErrorRetryWidget(
                  message: ErrorRetryWidget.friendlyMessage(_error!),
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primaryBlue,
                  backgroundColor: AppColors.bgWhite,
                  child: Column(
                  children: [
                _buildDaySelector(),
                Expanded(
                  child: classes.isEmpty 
                  ? AnimatedListItem(
                      index: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_outlined, size: 64, color: AppColors.textTertiary.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No classes scheduled for $selectedDay',
                              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.xl,
                        crossAxisSpacing: AppSpacing.xl,
                        mainAxisExtent: 110,
                      ),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final c = classes[index];
                        return AnimatedListItem(
                          index: index,
                          key: ValueKey('${selectedDay}_$index'),
                          child: Container(
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
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (c['code'] ?? '').toUpperCase(),
                                        style: AppTextStyles.headline.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                        c['time'] ?? 'N/A',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                          color: AppColors.brandOrangeGlow,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c['room'] ?? 'Room',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Type-${c['type'] ?? ''}",
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF878D96), // Solid equivalent of Primary with 0.5 opacity
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Group-${(c['group']?.isNotEmpty ?? false) ? c['group'] : 'All'}",
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF878D96), // Solid equivalent
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ],
            ),
      ),
    );
  }
}
