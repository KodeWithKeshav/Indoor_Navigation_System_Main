import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../admin_map/presentation/providers/admin_map_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';

const Color deepVoidBlue = Color(0xFF0F172A);
const Color electricGrid = Color(0xFF38BDF8);
const Color paperWhite = Color(0xFFE2E8F0);
const Color darkCardColor = Color(0xFF1E293B);

/// Displays the user's profile information and account settings.
///
/// Allows the user to view their email, organization ID, and update their password.
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isEditingPassword = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: deepVoidBlue,
      appBar: AppBar(
        backgroundColor: deepVoidBlue,
        iconTheme: const IconThemeData(color: electricGrid),
        title: const Text(
          'My Profile',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: electricGrid.withOpacity(0.2),
                    child: Text(
                      user?.email.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: electricGrid,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.role == 'student'
                        ? 'Student Account'
                        : 'Guest Account',
                    style: const TextStyle(
                      color: paperWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "ACCOUNT DETAILS",
              style: TextStyle(
                color: electricGrid,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildReadOnlyField("Email Address", user?.email ?? 'Unknown'),
            const SizedBox(height: 16),
            _buildOrganizationField(user?.organizationId),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SECURITY",
                  style: TextStyle(
                    color: electricGrid,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditingPassword)
                  TextButton(
                    onPressed: () => setState(() => _isEditingPassword = true),
                    child: const Text(
                      "Change Password",
                      style: TextStyle(color: electricGrid),
                    ),
                  ),
              ],
            ),

            if (_isEditingPassword) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: darkCardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: electricGrid.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: paperWhite),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(
                          color: paperWhite.withOpacity(0.6),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: electricGrid),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      style: const TextStyle(color: paperWhite),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color: paperWhite.withOpacity(0.6),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: electricGrid),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _isEditingPassword = false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: electricGrid,
                            foregroundColor: deepVoidBlue,
                          ),
                          onPressed: () {
                            if (_passwordController.text !=
                                _confirmController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Passwords do not match"),
                                ),
                              );
                              return;
                            }
                            setState(() => _isEditingPassword = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password updated successfully (Mock)",
                                ),
                              ),
                            );
                          },
                          child: const Text("Update"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper widget to build a read-only text field with a label.
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: paperWhite.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            value,
            style: const TextStyle(color: paperWhite, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Builds the organization field with a change button.
  Widget _buildOrganizationField(String? currentOrgId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Organization ID",
              style: TextStyle(
                color: paperWhite.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: () => _showOrganizationDialog(currentOrgId),
              child: const Text(
                "Change",
                style: TextStyle(color: electricGrid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            currentOrgId != null && currentOrgId.isNotEmpty
                ? currentOrgId
                : 'None',
            style: const TextStyle(color: paperWhite, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Shows a dialog to select an organization.
  void _showOrganizationDialog(String? currentOrgId) {
    // Capture the scaffold messenger BEFORE showing dialog
    // so we use the profile screen's context, not the dialog's.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, _) {
          final organizationsAsync = dialogRef.watch(organizationsProvider);

          return AlertDialog(
            backgroundColor: darkCardColor,
            title: const Text(
              'Select Organization',
              style: TextStyle(color: paperWhite),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: organizationsAsync.when(
                data: (orgs) {
                  if (orgs.isEmpty) {
                    return const Text(
                      'No organizations found.',
                      style: TextStyle(color: Colors.white60),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: orgs.length,
                    itemBuilder: (context, index) {
                      final org = orgs[index];
                      final isSelected = org.id == currentOrgId;

                      return ListTile(
                        title: Text(
                          org.name,
                          style: const TextStyle(color: paperWhite),
                        ),
                        subtitle: Text(
                          org.id,
                          style: TextStyle(color: paperWhite.withOpacity(0.5)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: electricGrid)
                            : null,
                        onTap: () {
                          // Close dialog first
                          Navigator.pop(dialogContext);
                          // Then update using the widget's own ref
                          _updateOrganization(scaffoldMessenger, org.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: electricGrid),
                ),
                error: (e, s) => Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Updates the user's organization in Firestore and refreshes local state.
  Future<void> _updateOrganization(
    ScaffoldMessengerState scaffoldMessenger,
    String newOrgId,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.updateUserOrganization(
        uid: user.id,
        organizationId: newOrgId,
      );

      result.fold(
        (failure) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to update: ${failure.message}')),
          );
        },
        (_) {
          // Immediately update the local user state so the UI rebuilds
          final updatedUser = UserEntity(
            id: user.id,
            email: user.email,
            role: user.role,
            organizationId: newOrgId,
          );
          ref.read(currentUserProvider.notifier).setUser(updatedUser);

          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Organization updated successfully')),
          );
        },
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
