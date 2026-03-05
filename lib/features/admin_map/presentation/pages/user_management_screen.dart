import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/user_management_controller.dart';
import '../widgets/admin_drawer.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gridScrollController;

  // --- THEME COLORS ---
  static const deepVoidBlue = Color(0xFF020617);
  static const topLightBlue = Color(0xFF1E3A8A);
  static const electricGrid = Color(0xFF38BDF8);
  static const darkCardColor = Color(0xFF1A1F2C);
  static const paperWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    // Background animation setup
    _gridScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final isUpdating = ref.watch(userManagementControllerProvider);

    return Scaffold(
      backgroundColor: deepVoidBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'SECURITY PROTOCOL',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 10,
                color: electricGrid,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'USER DATABASE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: deepVoidBlue.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: electricGrid),
        titleTextStyle: const TextStyle(color: paperWhite),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: electricGrid.withOpacity(0.2), height: 1.0),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Stack(
        children: [
          // 0. GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [topLightBlue, deepVoidBlue],
                stops: [0.0, 0.8],
              ),
            ),
          ),

          // 1. ANIMATED GRID
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridScrollController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BlueprintGridPainter(
                    scrollOffset: _gridScrollController.value,
                    lineColor: electricGrid.withOpacity(0.1),
                  ),
                );
              },
            ),
          ),

          // 2. CONTENT
          SafeArea(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      "NO RECORDS FOUND",
                      style: TextStyle(
                        color: paperWhite.withOpacity(0.5),
                        fontFamily: 'Courier',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user, isUpdating);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: electricGrid),
              ),
              error: (e, _) => Center(
                child: Text(
                  'SYSTEM ERROR: $e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),

          // 3. LOADING OVERLAY
          if (isUpdating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: electricGrid),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildUserCard(UserEntity user, bool isUpdating) {
    final isAdmin = user.role == UserRole.admin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: darkCardColor.withOpacity(0.9),
        border: Border.all(
          color: isAdmin
              ? Colors.redAccent.withOpacity(0.5)
              : electricGrid.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAdmin
                ? Colors.redAccent.withOpacity(0.1)
                : electricGrid.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAdmin
                  ? Colors.redAccent.withOpacity(0.5)
                  : electricGrid.withOpacity(0.3),
            ),
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            color: isAdmin ? Colors.redAccent : electricGrid,
            size: 20,
          ),
        ),
        title: Text(
          user.email.toUpperCase(),
          style: const TextStyle(
            color: paperWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 13,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                'ACCESS LEVEL: ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                user.role.name.toUpperCase(),
                style: TextStyle(
                  color: isAdmin ? Colors.redAccent : electricGrid,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 100,
          height: 32,
          child: isAdmin
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _updateRole(context, ref, user, UserRole.user),
                  child: const Text(
                    'DEMOTE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricGrid,
                    foregroundColor: deepVoidBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _updateRole(context, ref, user, UserRole.admin),
                  child: const Text(
                    'PROMOTE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
        ),
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _updateRole(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
    UserRole newRole,
  ) async {
    try {
      await ref
          .read(userManagementControllerProvider.notifier)
          .updateUserRole(user.id, newRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PERMISSIONS UPDATED: ${user.email} -> ${newRole.name.toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                color: deepVoidBlue,
              ),
            ),
            backgroundColor: electricGrid,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OPERATION FAILED: $e',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// --- PAINTER (Consistent with other screens) ---
class BlueprintGridPainter extends CustomPainter {
  final double scrollOffset;
  final Color lineColor;
  BlueprintGridPainter({required this.scrollOffset, required this.lineColor});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const gridSize = 40.0;
    final shift = (scrollOffset * gridSize);
    for (double x = -gridSize; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x + shift % gridSize, 0),
        Offset(x + shift % gridSize, size.height),
        paint,
      );
    }
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + shift % gridSize),
        Offset(size.width, y + shift % gridSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) => true;
}
