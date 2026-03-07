import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/quick_access_service.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';

class QuickAccessSettingsScreen extends StatefulWidget {
  const QuickAccessSettingsScreen({super.key});

  @override
  State<QuickAccessSettingsScreen> createState() => _QuickAccessSettingsScreenState();
}

class _QuickAccessSettingsScreenState extends State<QuickAccessSettingsScreen> {
  final _authService = AuthService();
  final _quickAccessService = QuickAccessService();
  
  List<dynamic> _allMenus = [];
  List<String> _selectedTitles = [];
  bool _loading = true;

  final Map<String, IconData> _menuIcons = {
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final menus = await _authService.getMenus();
    await _quickAccessService.init();
    
    if (mounted) {
      setState(() {
        _allMenus = menus.where((m) => 
          m['MenuText'] != null && 
          m['MenuText'] != 'Announcements' && 
          m['MenuText'] != 'Messages' &&
          m['RouteName'] != 'OutAppBrowser'
        ).toList();
        _selectedTitles = List.from(_quickAccessService.selectedItemsNotifier.value);
        _loading = false;
      });
    }
  }

  void _toggleItem(String title) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTitles.contains(title)) {
        _selectedTitles.remove(title);
      } else {
        if (_selectedTitles.length < 8) {
          _selectedTitles.add(title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Max 8 items allowed for Quick Access')),
          );
        }
      }
    });
    _quickAccessService.saveItems(_selectedTitles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Quick Access', style: AppTextStyles.title3),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: _allMenus.length,
              itemBuilder: (context, index) {
                final item = _allMenus[index];
                final title = item['MenuText'] as String;
                final isSelected = _selectedTitles.contains(title);
                final icon = _menuIcons[title] ?? Icons.grid_view_rounded;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: GestureDetector(
                    onTap: () => _toggleItem(title),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primaryBlue.withValues(alpha: 0.02)
                            : AppColors.bgDashboard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primaryBlue.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.08),
                            offset: const Offset(6, 6),
                            blurRadius: 12,
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-6, -6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                  : AppColors.bgDashboard,
                              shape: BoxShape.circle,
                              boxShadow: isSelected ? null : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2, -2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon, 
                              color: isSelected ? AppColors.primaryBlue : AppColors.textTertiary, 
                              size: 24
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue)
                          else
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Extension to support inset shadows if not natively available in your BoxDecoration
// Since standard BoxDecoration doesn't support 'inset', I will use a custom implementation 
// or stick to a simple color tint for 'selected' state to avoid adding more complex dependencies.
// Actually, I'll use a subtle color tint and a different border to signify selection.
extension on BoxDecoration {
  // Mocking inset as it's not standard. I'll change the implementation above.
}
