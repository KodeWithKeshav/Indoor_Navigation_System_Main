import 'package:flutter/material.dart';

const Color deepVoidBlue = Color(0xFF0F172A);
const Color electricGrid = Color(0xFF38BDF8);
const Color paperWhite = Color(0xFFE2E8F0);
const Color darkCardColor = Color(0xFF1E293B);

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepVoidBlue,
      appBar: AppBar(
        backgroundColor: deepVoidBlue,
        iconTheme: const IconThemeData(color: electricGrid),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: paperWhite,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: electricGrid.withOpacity(0.3), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "HOW CAN WE HELP?",
            style: TextStyle(
              color: electricGrid,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildSupportCard(
            context,
            icon: Icons.bug_report_outlined,
            title: "Report a Problem",
            subtitle: "Found a bug? Let us know.",
            onTap: () => _showReportDialog(context),
          ),
          const SizedBox(height: 16),

          _buildSupportCard(
            context,
            icon: Icons.email_outlined,
            title: "Contact Administration",
            subtitle: "admin@university.edu",
            onTap: () => _showContactDialog(context),
          ),
          const SizedBox(height: 16),

          _buildSupportCard(
            context,
            icon: Icons.question_answer_outlined,
            title: "FAQs",
            subtitle: "Common questions about navigation.",
            onTap: () => _showFaqsDialog(context),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "Emergency Contact: 555-0199",
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: darkCardColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: electricGrid.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: electricGrid.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: electricGrid),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: paperWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: paperWhite.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: paperWhite.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: electricGrid.withOpacity(0.5)),
        ),
        title: const Text(
          'Report a Problem',
          style: TextStyle(
            color: electricGrid,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue you encountered with the navigation system or campus map.',
              style: TextStyle(color: paperWhite, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: paperWhite),
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: TextStyle(color: paperWhite.withOpacity(0.3)),
                filled: true,
                fillColor: deepVoidBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: electricGrid,
              foregroundColor: deepVoidBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Thank you! Your bug report has been submitted to IT Support.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: electricGrid.withOpacity(0.5)),
        ),
        title: const Text(
          'Contact Administration',
          style: TextStyle(
            color: electricGrid,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactRow(Icons.email, 'Email', 'admin@university.edu'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.phone, 'Phone', '+1 (555) 0198-442'),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.location_on,
              'Office',
              'Building A, Room 101',
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.access_time,
              'Hours',
              'Mon-Fri, 9:00 AM - 5:00 PM',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: electricGrid)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: electricGrid.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: paperWhite.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: paperWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFaqsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: deepVoidBlue, // slightly darker for big list
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: electricGrid.withOpacity(0.5)),
        ),
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: electricGrid,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildFaqItem(
                'How do I find a room?',
                'Use the Search bar on the home screen or tap directly on the map to select a destination room. Then press Start Navigation.',
              ),
              _buildFaqItem(
                'Is there an accessible route option?',
                'Yes! When planning a trip, toggle the "Accessible Route" switch to prioritize elevators over stairs.',
              ),
              _buildFaqItem(
                'Why is my location not updating?',
                'Ensure that Location Services and Bluetooth are enabled on your device. The app relies on internal beacons and pedometer data.',
              ),
              _buildFaqItem(
                'How does Voice Guidance work?',
                'Voice guidance uses your device text-to-speech to read out directional instructions. You can toggle it off in the Sidebar Settings.',
              ),
              _buildFaqItem(
                'Can I use the app offline?',
                'The map assets are cached locally, but live routing requires an active campus network connection.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: electricGrid)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: ThemeData.dark().copyWith(
        dividerColor: Colors.transparent,
        unselectedWidgetColor: electricGrid,
        colorScheme: const ColorScheme.dark(primary: electricGrid),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: paperWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        iconColor: electricGrid,
        collapsedIconColor: electricGrid.withOpacity(0.7),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: paperWhite.withOpacity(0.7),
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
