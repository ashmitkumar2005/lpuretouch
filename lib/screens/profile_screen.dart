import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/animated_list_item.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name =
        user['StudentName'] ?? user['ExtractedName'] ?? 'Student';
    final initials = name
        .toString()
        .trim()
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
        .join();
    final regNo =
        (user['RegNo'] ?? user['RegisterationNumber'] ?? 'N/A').toString();
    final email =
        (user['StudentEmail'] ?? user['Email'] ?? 'N/A').toString();
    final program =
        (user['ProgramName'] ?? user['Program'] ?? 'N/A').toString();
    final session = (user['AdmissionSession'] ?? 'N/A').toString();

    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Semantics(
          header: true,
          child: const Text('Account', style: AppTextStyles.navBarTitle),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Digital ID QR Code',
            child: Tooltip(
              message: 'Digital ID',
              child: _CircularActionButton(
                icon: Icons.qr_code_outlined,
                onTap: () => _showDigitalIDModal(context),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Logout',
            child: _CircularActionButton(
              icon: Icons.logout_outlined,
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) {
                  // Tell GlobalLayout to hide the dock immediately
                  GlobalLayout.of(context)?.refreshAuthState();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Avatar with ring
            AnimatedListItem(
              index: 0,
              child: Center(
                child: Hero(
                  tag: 'user-avatar',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      // Outer ring with 3px padding + 3px border
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          width: 3,
                        ),
                      ),
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.avatarGradA, AppColors.avatarGradB],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.title1.copyWith(
                              color: AppColors.avatarInitials,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Name + email
            AnimatedListItem(
              index: 1,
              child: Semantics(
                header: true,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title2.copyWith(letterSpacing: -0.8),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedListItem(
              index: 2,
              child: Text(
                email != 'N/A' ? email : regNo,
                style: AppTextStyles.subhead,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Academic card
            AnimatedListItem(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: AppShadows.cardSoft,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.bgDashboard,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(Icons.school_outlined,
                              color: AppColors.primaryBlue, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Academic Program',
                                  style: AppTextStyles.footnote),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      program,
                                      style: AppTextStyles.headline,
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm + 2,
                                        vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text('Active',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ],
                              ),
                              Text('Session: $session',
                                  style: AppTextStyles.subhead),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      button: true,
                      label: 'View academic details',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('View Academic Details',
                                style: AppTextStyles.headline),
                            Icon(Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Action tiles
            AnimatedListItem(
              index: 4,
              child: _AccountActionTile(
                icon: Icons.person_search_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Basic Details',
                subtitle: 'Father, Mother, DOB, Gender',
                onTap: () => _showDetailsModal(context, 'Basic Details', {
                  "Father's Name": user['FatherName']?.toString() ?? 'N/A',
                  "Mother's Name": user['MotherName']?.toString() ?? 'N/A',
                  'Date of Birth': user['DateofBirth']?.toString() ?? 'N/A',
                  'Gender': user['Gender']?.toString() ?? 'N/A',
                }),
              ),
            ),
            AnimatedListItem(
              index: 5,
              child: _AccountActionTile(
                icon: Icons.contact_emergency_outlined,
                iconColor: AppColors.success,
                title: 'Contact Details',
                subtitle: 'Permanent & Correspondence Address',
                onTap: () => _showDetailsModal(context, 'Contact Details', {
                  'Mobile': user['StudentMobile']?.toString() ?? 'N/A',
                  'Email': email,
                  'Permanent Address': _formatAddress(user['PermanentAddress']),
                  'Correspondence Address':
                      _formatAddress(user['CorrespondenceAddress']),
                }),
              ),
            ),
            AnimatedListItem(
              index: 6,
              child: _AccountActionTile(
                icon: Icons.history_edu_outlined,
                iconColor: AppColors.warning,
                title: 'Admission Info',
                subtitle: 'Section, Batch, Agg Attendance',
                onTap: () => _showDetailsModal(context, 'Admission Info', {
                  'Section': user['Section']?.toString() ?? 'N/A',
                  'BatchYear': user['BatchYear']?.toString() ?? 'N/A',
                  'Agg. Attendance': user['AggAttendance']?.toString() ?? 'N/A',
                  'Category': user['CategoryCode']?.toString() ?? 'N/A',
                }),
              ),
            ),
            AnimatedListItem(
              index: 7,
              child: _AccountActionTile(
                icon: Icons.meeting_room_outlined,
                iconColor: const Color(0xFFEC4899),
                title: 'Stay Information',
                subtitle: 'Hostel, Room Status & More',
                onTap: () {
                  final Map<String, String> stayDetails = {};
                  final hostelRaw = user['Hostel']?.toString() ?? 'N/A';
                  if (hostelRaw.toLowerCase().contains('boys hostel')) {
                    stayDetails['Boys Hostel'] = hostelRaw
                        .replaceAll(
                            RegExp(r'Boys Hostel', caseSensitive: false), '')
                        .trim();
                  } else if (hostelRaw.toLowerCase().contains('girls hostel')) {
                    stayDetails['Girls Hostel'] = hostelRaw
                        .replaceAll(
                            RegExp(r'Girls Hostel', caseSensitive: false), '')
                        .trim();
                  } else {
                    stayDetails['Hostel Details'] = hostelRaw;
                  }
                  stayDetails['Room Status'] =
                      user['RmsStatusCount']?.toString() ?? 'N/A';
                  _showDetailsModal(context, 'Stay Information', stayDetails);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.dockBuffer),
          ],
        ),
      ),
    );
  }

  // ─── Modal Helpers ──────────────────────────────────────────────────────────

  void _showDigitalIDModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) => _DigitalIDModal(user: user),
    );
  }

  void _showDetailsModal(
      BuildContext context, String title, Map<String, String> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH),
              child: ListView(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Step 12: Drag handle
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(
                          bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Text(title,
                      style: AppTextStyles.largeTitle
                          .copyWith(fontSize: 26)),
                  const SizedBox(height: AppSpacing.xxl),
                  ...details.entries.map((e) {
                    final cleanedValue = _cleanValue(e.value);
                    if (cleanedValue.isEmpty || cleanedValue == 'N/A') {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.bgDashboard,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                            color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(cleanedValue,
                              style: AppTextStyles.subhead.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              )),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _cleanValue(String val) {
    if (val == 'N/A' || val.trim().isEmpty) return 'N/A';
    String cleaned = val.trim();
    cleaned = cleaned.replaceAll(RegExp(r'Dear Student(\(\d+\))?'), '');
    if (cleaned.contains('*')) {
      final parts = cleaned
          .split('*')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length > 1) return parts.map((p) => '• $p').join('\n\n');
    }
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\*+', multiLine: true), '• ');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\*+'), '\n• ');
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim().isEmpty ? 'N/A' : cleaned.trim();
  }

  String _formatAddress(dynamic address) {
    if (address == null) return 'N/A';
    if (address is String) return address;
    if (address is Map) {
      final parts = [
        address['HNo_Building'],
        address['Colony'],
        address['CityName'],
        address['DistrictName'],
        address['StateName'],
        address['CountryName'],
        address['PinCode'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
      return parts.isEmpty ? 'N/A' : parts.join(', ');
    }
    return address.toString();
  }
}

// ─── Circular Action Button (AppBar) ─────────────────────────────────────────
class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSpacing.massive,
        height: AppSpacing.massive,
        margin: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          shape: BoxShape.circle,
          boxShadow: AppShadows.cardSoft,
        ),
        child: Icon(icon,
            color: AppColors.textPrimary.withOpacity(0.8), size: 22),
      ),
    );
  }
}

// ─── Digital ID Modal ─────────────────────────────────────────────────────────
class _DigitalIDModal extends StatefulWidget {
  final Map<String, dynamic> user;
  const _DigitalIDModal({required this.user});

  @override
  State<_DigitalIDModal> createState() => _DigitalIDModalState();
}

class _DigitalIDModalState extends State<_DigitalIDModal> {
  String? _qrBase64;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQR();
  }

  Future<void> _loadQR() async {
    final qr = await AuthService().fetchStudentQR();
    if (mounted) {
      setState(() {
        _qrBase64 = qr;
        _isLoading = false;
        if (qr == null) _error = 'Failed to fetch Digital ID';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.user['StudentName'] ?? widget.user['ExtractedName'] ?? 'Student';
    final regNo =
        (widget.user['RegNo'] ?? widget.user['RegisterationNumber'] ?? '')
            .toString();

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step 12: drag handle
          Center(
            child: Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Text('Digital ID', style: AppTextStyles.title2),
          const SizedBox(height: AppSpacing.sm),
          Text('Scan this QR for attendance',
              style: AppTextStyles.subhead),
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.bgDashboard,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                if (_isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryBlue)),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: AppSpacing.lg),
                          Text(_error!,
                              style: AppTextStyles.footnote
                                  .copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  )
                else if (_qrBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(
                      base64Decode(_qrBase64!),
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
                Text(name, style: AppTextStyles.headline),
                Text(regNo, style: AppTextStyles.footnote),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                elevation: 0,
              ),
              child: const Text('Dismiss', style: AppTextStyles.buttonLabel),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─── Account Action Tile ──────────────────────────────────────────────────────
class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.massive,
                  height: AppSpacing.massive,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headline),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.subhead),
                    ],
                  ),
                ),
                // Trailing chevron on EVERY tile
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
