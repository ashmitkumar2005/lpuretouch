import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/app_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';

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
    final sessionRaw = (user['AdmissionSession'] ?? 'N/A').toString();
    final session = sessionRaw.split('-')[0];

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
            child: _CircularActionButton(
              icon: Icons.qr_code_outlined,
              onTap: () => _showDigitalIDModal(context),
            ),
          ),
          Semantics(
            button: true,
            label: 'Logout',
            child: _CircularActionButton(
              icon: Icons.logout_outlined,
              onTap: () => _showLogoutConfirmation(context),
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
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgDashboard, // Match background for neumorphic effect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        offset: const Offset(-4, -4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.largeTitle.copyWith(
                          color: AppColors.primaryBlue,
                          fontSize: 32,
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
                regNo,
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Academic card (Neumorphic)
            AnimatedListItem(
              index: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.bgDashboard,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: const Offset(-5, -5),
                      blurRadius: 15,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(5, 5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.school_outlined, color: AppColors.textPrimary.withValues(alpha: 0.7), size: 24),
                              ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ACADEMIC PROGRAM',
                                  style: AppTextStyles.caption.copyWith(
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                program,
                                style: AppTextStyles.headline.copyWith(
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 2),
                              Text('Session: $session',
                                  style: AppTextStyles.subhead.copyWith(
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ],
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
                icon: Icons.person_outline_rounded,
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
                icon: Icons.contact_mail_outlined,
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
                icon: Icons.assignment_outlined,
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
                icon: Icons.home_outlined,
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxl)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 32),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Logout?', style: AppTextStyles.title2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Are you sure you want to sign out of your account?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        child: Text('Cancel',
                            style: AppTextStyles.buttonLabel
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          await AuthService().logout();
                          if (context.mounted) {
                            GlobalLayout.of(context)?.refreshAuthState();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login', (r) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        child: const Text('Logout',
                            style: AppTextStyles.buttonLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDigitalIDModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allow BackdropFilter to show
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: _DigitalIDModal(user: user),
        ),
      ),
    );
  }

  void _showDetailsModal(
      BuildContext context, String title, Map<String, String> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
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
        ),
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
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final qr = await AuthService().fetchStudentQR();
      if (mounted) {
        setState(() {
          _qrBase64 = qr;
          _isLoading = false;
          if (qr == null) _error = 'No QR identity found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is DioException ? 'Network Error: Check Connection' : e.toString();
          _isLoading = false;
        });
      }
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
                        child: ShimmerLoading(width: 150, height: 150)),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 250,
                    child: ErrorRetryWidget(
                      message: ErrorRetryWidget.friendlyMessage(_error!),
                      onRetry: _loadQR,
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
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color iconColor = AppColors.textPrimary; // Monochromatic
    return Semantics(
      button: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgDashboard,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.white,
                offset: const Offset(-4, -4),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(4, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor.withValues(alpha: 0.7), size: 22),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.headline.copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: AppTextStyles.subhead.copyWith(
                                fontSize: 12,
                                color: AppColors.textPrimary.withValues(alpha: 0.5),
                              )),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textPrimary.withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
