import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Extract info
    final name = user['StudentName'] ?? user['ExtractedName'] ?? 'Student';
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _CircularActionButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircularActionButton(
              icon: Icons.qr_code_scanner_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const _QRScannerScreen()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _CircularActionButton(
              icon: Icons.edit_outlined,
              onTap: () {},
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFA3E635), // Life green color from mockup
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.person, size: 70, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              email != 'N/A' ? email : regNo,
              style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),
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
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ),
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
              title: "Stay Details",
              subtitle: "Hostel, Messages, RmsStatus",
              onTap: () => _showDetailsModal(context, "Stay Details", {
                "Hostel": user['Hostel']?.toString() ?? 'N/A',
                "Messages": user['MyMessagesCount']?.toString() ?? '0',
                "RMS Status": user['RmsStatusCount']?.toString() ?? 'N/A',
              }),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }
}

class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    controller.stop();

    // Call API
    final result = await AuthService().markHostelAttendance(code);
    
    if (!mounted) return;

    // Show result
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QRResultModal(result: result),
    );

    if (mounted) {
      Navigator.pop(context); // Close scanner after showing result
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scoped scanning area overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: _CircularActionButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          // Info Text
          const Align(
            alignment: Alignment(0, 0.5),
            child: Text(
              'Align QR code within the frame',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRResultModal extends StatelessWidget {
  final Map<String, dynamic> result;
  const _QRResultModal({required this.result});

  @override
  Widget build(BuildContext context) {
    final status = result['status']?.toString() ?? '0';
    final isSuccess = status == '1';
    final message = _cleanString(result['message']?.toString() ?? 'Unknown error');
    final studentName = result['studentName']?.toString() ?? 'Student';
    // LPU provides a hex color in colorCode, default to green for success, red for fail
    final colorHex = result['colorCode']?.toString() ?? (isSuccess ? '#10B981' : '#EF4444');
    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: color,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSuccess ? 'Success' : 'Attendance Failed',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            studentName,
            style: TextStyle(color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
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
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanString(String val) {
    return val.replaceAll(RegExp(r'Dear Student(\(\d+\))?'), '').trim();
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
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
