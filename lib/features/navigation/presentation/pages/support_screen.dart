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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report feature coming soon.")),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildSupportCard(
            context,
            icon: Icons.email_outlined,
            title: "Contact Administration",
            subtitle: "admin@university.edu",
            onTap: () {
              // Mock Link
            },
          ),
          const SizedBox(height: 16),

          _buildSupportCard(
            context,
            icon: Icons.question_answer_outlined,
            title: "FAQs",
            subtitle: "Common questions about navigation.",
            onTap: () {
              // Mock Link
            },
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
}
