import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Extract info we realistically have from PVRResult
    final name = user['ExtractedName'] ?? 'Student';
    final regNo = user['RegNo'] ?? 'N/A';
    final program = user['Program'] ?? 'N/A';
    
    // Attempt to pull out extra fields if they casually exist in the login result, 
    // otherwise default to N/A until the specific Profile API is linked.
    final email = user['Email'] ?? user['EmailId'] ?? 'N/A';
    final contact = user['ContactNo'] ?? user['Mobile'] ?? 'N/A';
    final dob = user['DOB'] ?? user['DateOfBirth'] ?? 'N/A';
    final gender = user['Gender'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E), // Dark grey
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF26522), // Orange
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Text('(QR)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF897A), Color(0xFFFFCC70)], // Orange to Yellow gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    regNo,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Base details list
            _buildSectionHeader('Basic'),
            _buildDetailRow("Father's Name", user['FatherName'] ?? 'N/A'),
            _buildDetailRow("Mother's Name", user['MotherName'] ?? 'N/A'),
            _buildDetailRow("Permanent Address", user['PermanentAddress'] ?? 'N/A'),
            _buildDetailRow("Correspondence Address", user['CorrespondenceAddress'] ?? 'N/A'),
            _buildDetailRow("Contact No.", contact),
            _buildDetailRow("Email", email),
            _buildDetailRow("Date Of Birth", dob),
            _buildDetailRow("Gender", gender),

            _buildSectionHeader('Academic Details'),
            _buildDetailRow("Program", program),
            _buildDetailRow("Admission Session", user['AdmissionSession'] ?? 'N/A'),
            _buildDetailRow("Batch", user['Batch'] ?? 'N/A'),
            _buildDetailRow("Section", user['Section'] ?? 'N/A'),
            _buildDetailRow("TPC", user['TPC'] ?? 'Not Applicable'),

            _buildSectionHeader('Hostel Details'),
            _buildDetailRow("Hostel", user['Hostel'] ?? 'N/A'),
            _buildDetailRow("Warden", user['Warden'] ?? 'N/A'),
            _buildDetailRow("Allocated Mess", user['AllocatedMess'] ?? 'N/A'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF333333),
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
