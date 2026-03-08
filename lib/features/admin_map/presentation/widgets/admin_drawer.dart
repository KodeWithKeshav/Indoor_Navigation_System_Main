import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/providers/settings_provider.dart';

class AdminDrawer extends ConsumerWidget {
  final String? organizationId;
  const AdminDrawer({super.key, this.organizationId});

  // --- THEME COLORS ---
  static const deepVoidBlue = Color(0xFF020617);
  static const electricGrid = Color(0xFF38BDF8);
  static const darkCardColor = Color(0xFF1A1F2C);
  static const paperWhite = Colors.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: deepVoidBlue, // Dark Background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Squared off for tech look
      ),
      child: Column(
        children: [
          // 1. TECH HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              24,
              48,
              24,
              24,
            ), // Extra top padding
            decoration: const BoxDecoration(
              color: darkCardColor,
              border: Border(bottom: BorderSide(color: electricGrid, width: 2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: electricGrid.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: electricGrid),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 32,
                    color: electricGrid,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ADMIN CONSOLE',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: paperWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'ACCESS LEVEL: ROOT',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: electricGrid,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // 2. MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildTechTile(
                  icon: Icons.domain,
                  label: 'ORGANIZATION UNITS',
                  onTap: () {
                    context.go('/admin'); // Go back to Org List
                    Navigator.pop(context);
                  },
                ),
                _buildTechTile(
                  icon: Icons.people_outline,
                  label: 'USER MANAGEMENT',
                  onTap: () {
                    if (organizationId != null) {
                      context.go('/admin/dashboard/$organizationId/users');
                    } else {
                      context.go('/admin/users');
                    }
                    Navigator.pop(context);
                  },
                ),
                if (organizationId != null) ...[
                  const Divider(color: Colors.white10),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      "CONTEXT: ACTIVE ORG",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Divider(color: Colors.white10),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    "SYSTEM SETTINGS",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final isVoiceOn = ref
                        .watch(settingsProvider)
                        .isVoiceEnabled;
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      secondary: Icon(
                        isVoiceOn ? Icons.volume_up : Icons.volume_off,
                        color: isVoiceOn ? Colors.greenAccent : Colors.white38,
                        size: 22,
                      ),
                      title: Text(
                        'VOICE GUIDANCE',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: isVoiceOn ? paperWhite : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      subtitle: Text(
                        isVoiceOn ? 'ENABLED' : 'DISABLED',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: isVoiceOn
                              ? Colors.greenAccent
                              : Colors.white30,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      value: isVoiceOn,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) =>
                          ref.read(settingsProvider.notifier).toggleVoice(val),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. LOGOUT FOOTER
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: _buildTechTile(
              icon: Icons.power_settings_new,
              label: 'TERMINATE SESSION',
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: darkCardColor,
                    title: const Text('Confirm Logout', style: TextStyle(color: electricGrid)),
                    content: const Text('Are you sure you want to terminate your session?', style: TextStyle(color: paperWhite)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authControllerProvider.notifier).logout(context);
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTechTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : paperWhite;
    final iconColor = isDestructive ? Colors.redAccent : electricGrid;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Courier',
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      onTap: onTap,
      hoverColor: electricGrid.withOpacity(0.1),
    );
  }
}
