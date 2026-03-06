import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Extract info
    final name = user['StudentName'] ?? user['ExtractedName'] ?? 'Student';
    final initials = name.toString().trim().split(' ').take(2).map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').join();
    final regNo = (user['RegNo'] ?? user['RegisterationNumber'] ?? 'N/A').toString();
    final email = (user['StudentEmail'] ?? user['Email'] ?? 'N/A').toString();
    final program = (user['ProgramName'] ?? user['Program'] ?? 'N/A').toString();
    final session = (user['AdmissionSession'] ?? 'N/A').toString();

    const primaryColor = Color(0xFF2050E4);
    const backgroundColor = Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevents default back button
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircularActionButton(
              icon: Icons.qr_code_outlined,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _DigitalIDModal(user: user),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircularActionButton(
              icon: Icons.logout_outlined,
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Image
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8),
            ),
            const SizedBox(height: 4),
            Text(
              email != 'N/A' ? email : regNo,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Plan Card (Academic Summary)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.school_outlined, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Academic Program',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    program,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Slightly smaller to fit better
                                    maxLines: 2, // Allow up to 2 lines
                                    overflow: TextOverflow.visible, // Let it wrap naturally within the 2 lines
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Active', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            Text(
                              'Session: $session',
                              style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'View Academic Details',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black.withValues(alpha: 0.25)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Items
            _AccountActionTile(
              icon: Icons.person_search_outlined,
              iconColor: const Color(0xFF6366F1),
              title: "Basic Details",
              subtitle: "Father, Mother, DOB, Gender",
              onTap: () => _showDetailsModal(context, "Basic Details", {
                "Father's Name": user['FatherName']?.toString() ?? 'N/A',
                "Mother's Name": user['MotherName']?.toString() ?? 'N/A',
                "Date of Birth": user['DateofBirth']?.toString() ?? 'N/A',
                "Gender": user['Gender']?.toString() ?? 'N/A',
              }),
            ),
            _AccountActionTile(
              icon: Icons.contact_emergency_outlined,
              iconColor: const Color(0xFF10B981),
              title: "Contact Details",
              subtitle: "Permanent & Correspondence Address",
              onTap: () => _showDetailsModal(context, "Contact Details", {
                "Mobile": user['StudentMobile']?.toString() ?? 'N/A',
                "Email": email,
                "Permanent Address": _formatAddress(user['PermanentAddress']),
                "Correspondence Address": _formatAddress(user['CorrespondenceAddress']),
              }),
            ),
            _AccountActionTile(
              icon: Icons.history_edu_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: "Admission Info",
              subtitle: "Section, Batch, Agg Attendance",
              onTap: () => _showDetailsModal(context, "Admission Info", {
                "Section": user['Section']?.toString() ?? 'N/A',
                "BatchYear": user['BatchYear']?.toString() ?? 'N/A',
                "Agg. Attendance": user['AggAttendance']?.toString() ?? 'N/A',
                "Category": user['CategoryCode']?.toString() ?? 'N/A',
              }),
            ),
            _AccountActionTile(
              icon: Icons.meeting_room_outlined,
              iconColor: const Color(0xFFEC4899),
              title: "Stay Information",
              subtitle: "Hostel, Room Status & More",
              onTap: () {
                final Map<String, String> stayDetails = {};
                final hostelRaw = user['Hostel']?.toString() ?? 'N/A';
                
                // Parse Hostel string for better headings
                if (hostelRaw.toLowerCase().contains('boys hostel')) {
                  stayDetails['Boys Hostel'] = hostelRaw.replaceAll(RegExp(r'Boys Hostel', caseSensitive: false), '').trim();
                } else if (hostelRaw.toLowerCase().contains('girls hostel')) {
                  stayDetails['Girls Hostel'] = hostelRaw.replaceAll(RegExp(r'Girls Hostel', caseSensitive: false), '').trim();
                } else {
                  stayDetails['Hostel Details'] = hostelRaw;
                }
                
                stayDetails['Room Status'] = user['RmsStatusCount']?.toString() ?? 'N/A';

                _showDetailsModal(context, "Stay Information", stayDetails);
              },
            ),
            
            const SizedBox(height: 120), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context, String title, Map<String, String> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(title, 
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...details.entries.map((e) {
                    final cleanedValue = _cleanValue(e.value);
                    if (cleanedValue.isEmpty || cleanedValue == 'N/A') return const SizedBox.shrink();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.03)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.key.toUpperCase(), 
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.4), 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(cleanedValue, 
                            style: const TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: Color(0xFF1F1F1F),
                            )
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }

  String _cleanValue(String val) {
    if (val == 'N/A' || val.trim().isEmpty) return 'N/A';
    
    // Step 1: Basic string cleaning
    String cleaned = val.trim();
    cleaned = cleaned.replaceAll(RegExp(r'Dear Student(\(\d+\))?'), '');
    
    // Step 2: Detect parts separated by '*' and convert to bullet points
    // LPU API often sends "Some Text *Another Text *Third Text"
    if (cleaned.contains('*')) {
      final parts = cleaned.split('*').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length > 1) {
        return parts.map((p) => '• $p').join('\n\n');
      }
    }

    // Replace any remaining leading asterisks
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\*+', multiLine: true), '• ');
    
    // Normalize mid-string repetitions of * with newlines
    cleaned = cleaned.replaceAll(RegExp(r'\s*\*+'), '\n• ');

    // Normalize whitespace
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
        address['PinCode']
      ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
      return parts.isEmpty ? 'N/A' : parts.join(', ');
    }
    return address.toString();
  }
}

class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black.withValues(alpha: 0.8), size: 22),
      ),
    );
  }
}

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
        if (qr == null) _error = "Failed to fetch Digital ID";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['StudentName'] ?? widget.user['ExtractedName'] ?? 'Student';
    final regNo = (widget.user['RegNo'] ?? widget.user['RegisterationNumber'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Digital ID',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan this QR for attendance',
            style: TextStyle(color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          
          // QR Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                if (_isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: Colors.black)),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else if (_qrBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(_qrBase64!),
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  regNo,
                  style: TextStyle(color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
