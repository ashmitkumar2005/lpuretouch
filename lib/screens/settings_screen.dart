import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/animated_list_item.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'quick_access_settings_screen.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _biometricService = BiometricService();
  bool _biometricsEnabled = false;
  bool _notificationsEnabled = true;
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supported = await _biometricService.isBiometricSupported();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool val) async {
    if (val) {
      // Prompt for auth to enable
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => _biometricsEnabled = true);
      }
    } else {
      // Just disable
      await _biometricService.setBiometricEnabled(false);
      setState(() => _biometricsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
        ),
        title: const Text('Settings', style: AppTextStyles.navBarTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          _buildSectionHeader('SECURITY'),
          if (_biometricSupported)
            AnimatedListItem(
              index: 0,
              child: _SettingsSwitchTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Login',
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
              ),
            ),
          
          if (!_biometricSupported)
            AnimatedListItem(
              index: 0,
              child: const _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Security Settings',
                subtitle: 'Biometrics not supported on this device',
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),
          _buildSectionHeader('APP EXPERIENCE'),
          AnimatedListItem(
            index: 2,
            child: _SettingsTile(
              icon: Icons.dashboard_customize_outlined,
              title: 'Customize Quick Access',
              subtitle: 'Edit home screen widgets',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickAccessSettingsScreen()),
              ),
            ),
          ),
          AnimatedListItem(
            index: 3,
            child: _SettingsSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
          ),
          AnimatedListItem(
            index: 4,
            child: _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Clear Cache',
              onTap: () => _showClearCacheConfirmation(context),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          _buildSectionHeader('ABOUT'),
          AnimatedListItem(
            index: 5,
            child: _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'LPU TOUCH v2.0',
              subtitle: 'Redesigned for premium experience',
            ),
          ),
          AnimatedListItem(
            index: 6,
            child: _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Give Feedback',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback section coming soon')),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          _buildSectionHeader('ACCOUNT'),
          AnimatedListItem(
            index: 7,
            child: _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: () => _showLogoutConfirmation(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _NeumorphicDialog(
        title: 'Logout?',
        content: 'Are you sure you want to sign out of your account?',
        icon: Icons.logout_rounded,
        iconColor: AppColors.error,
        actionLabel: 'Logout',
        actionColor: AppColors.error,
        onAction: () async {
          await AuthService().logout();
          if (context.mounted) {
            GlobalLayout.of(context)?.refreshAuthState();
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
          }
        },
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _NeumorphicDialog(
        title: 'Clear Cache?',
        content: 'This will clear temporary data files. You will not be logged out.',
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.primaryBlue,
        actionLabel: 'Clear',
        actionColor: AppColors.error,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared!')),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 2.0,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgDashboard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.footnote)
            : null,
        trailing: onTap != null 
            ? const Icon(Icons.arrow_forward_ios_rounded, size: 14) 
            : null,
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgDashboard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class _NeumorphicDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  const _NeumorphicDialog({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              // Large diffuse outer shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                offset: const Offset(0, 20),
                blurRadius: 40,
                spreadRadius: -5,
              ),
              // Simulated top light inner-like shadow
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-8, -8),
                blurRadius: 16,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header (Claymorphic)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Text content
                Text(title, style: AppTextStyles.title2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Buttons (Claymorphic)
                Row(
                  children: [
                    Expanded(
                      child: _ClayButton(
                        label: 'Cancel',
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _ClayButton(
                        label: actionLabel,
                        color: actionColor,
                        isFilled: true,
                        onTap: () {
                          Navigator.pop(context);
                          onAction();
                        },
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
}

class _ClayButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isFilled;
  final VoidCallback onTap;

  const _ClayButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            // Outer diffuse
            BoxShadow(
              color: isFilled 
                ? color.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
            // Light top highlight
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
          gradient: isFilled ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonLabel.copyWith(
            color: isFilled ? Colors.white : color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
