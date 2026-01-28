import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const Color deepVoidBlue = Color(0xFF0F172A);
const Color electricGrid = Color(0xFF38BDF8); 
const Color paperWhite = Color(0xFFE2E8F0);
const Color darkCardColor = Color(0xFF1E293B);

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
      // No Drawer
      appBar: AppBar(
        backgroundColor: deepVoidBlue,
        iconTheme: const IconThemeData(color: electricGrid),
        title: const Text('My Profile', style: TextStyle(color: paperWhite, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1), 
          child: Container(color: electricGrid.withOpacity(0.3), height: 1)
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
                       style: const TextStyle(color: electricGrid, fontSize: 32, fontWeight: FontWeight.bold),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     user?.role == 'student' ? 'Student Account' : 'Guest Account',
                     style: const TextStyle(color: paperWhite, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 32),
             
             const Text("ACCOUNT DETAILS", style: TextStyle(color: electricGrid, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             
             _buildReadOnlyField("Email Address", user?.email ?? 'Unknown'),
             const SizedBox(height: 16),
             _buildReadOnlyField("Organization ID", user?.organizationId ?? 'None'),
             
             const SizedBox(height: 40),
             
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("SECURITY", style: TextStyle(color: electricGrid, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                 if (!_isEditingPassword)
                   TextButton(
                     onPressed: () => setState(() => _isEditingPassword = true),
                     child: const Text("Change Password", style: TextStyle(color: electricGrid)),
                   )
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
                          labelStyle: TextStyle(color: paperWhite.withOpacity(0.6)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: electricGrid)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmController,
                        style: const TextStyle(color: paperWhite),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: paperWhite.withOpacity(0.6)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: electricGrid)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isEditingPassword = false),
                            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: electricGrid, foregroundColor: deepVoidBlue),
                            onPressed: () {
                               if (_passwordController.text != _confirmController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                                  return;
                               }
                               // Mock Update
                               setState(() => _isEditingPassword = false);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully (Mock)")));
                            }, 
                            child: const Text("Update"),
                          )
                        ],
                      )
                   ],
                 ),
               )
             ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(label, style: TextStyle(color: paperWhite.withOpacity(0.6), fontSize: 12)),
         const SizedBox(height: 4),
         Container(
           width: double.infinity,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.black26,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.white10),
           ),
           child: Text(value, style: const TextStyle(color: paperWhite, fontSize: 16)),
         )
      ],
    );
  }
}
