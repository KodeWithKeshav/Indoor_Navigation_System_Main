import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_map_providers.dart';
import '../../domain/usecases/add_organization_usecase.dart';
import '../../domain/usecases/get_organizations_usecase.dart';
import '../../domain/usecases/delete_organization_usecase.dart';
import '../../domain/usecases/update_organization_usecase.dart';
import '../../domain/entities/organization.dart';
import '../../../../core/usecase/usecase.dart';
// Make sure you import your AuthController to handle logout
import '../../../auth/presentation/providers/auth_controller.dart'; 
import '../widgets/admin_drawer.dart';

class OrganizationListScreen extends ConsumerStatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  ConsumerState<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends ConsumerState<OrganizationListScreen> with SingleTickerProviderStateMixin {
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
    final getOrgsUseCase = ref.watch(getOrganizationsUseCaseProvider);

    return Scaffold(
      backgroundColor: deepVoidBlue,
      // Use extendBodyBehindAppBar to let the gradient flow behind the header
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'ORGANIZATION UNITS',
          style: TextStyle(
            fontFamily: 'Courier', 
            fontWeight: FontWeight.bold, 
            letterSpacing: 2,
            fontSize: 16
          ),
        ),
        centerTitle: true,
        backgroundColor: deepVoidBlue.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: electricGrid),
        titleTextStyle: const TextStyle(color: paperWhite),
        // --- ADDED LOGOUT BUTTON HERE ---
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            tooltip: 'TERMINATE SESSION',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout(context);
            },
          ),
          const SizedBox(width: 8), // Right padding
        ],
        // Add a subtle border to the bottom of the app bar
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
            child: FutureBuilder<List<Organization>>(
              future: getOrgsUseCase(NoParams()).then((result) => result.getOrElse((l) => [])),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: electricGrid),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 64, color: electricGrid.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "NO DATA FOUND",
                          style: TextStyle(
                            color: paperWhite.withOpacity(0.5),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final orgs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orgs.length,
                  itemBuilder: (context, index) {
                    final org = orgs[index];
                    return _buildTechCard(org);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: electricGrid,
        foregroundColor: deepVoidBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTechCard(Organization org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: darkCardColor.withOpacity(0.9),
        border: Border.all(color: electricGrid.withOpacity(0.3)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: electricGrid.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.domain, color: electricGrid),
        ),
        title: Text(
          org.name.toUpperCase(),
          style: const TextStyle(
            color: paperWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            org.description,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () => context.go('/admin/dashboard/${org.id}'),
        trailing: Theme(
          data: Theme.of(context).copyWith(
            cardColor: darkCardColor,
            popupMenuTheme: PopupMenuThemeData(
              color: darkCardColor,
              textStyle: const TextStyle(color: paperWhite),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: electricGrid.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onSelected: (value) {
              if (value == 'edit') {
                _showAddEditDialog(org: org);
              } else if (value == 'delete') {
                _confirmDelete(org);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, color: electricGrid, size: 18),
                  SizedBox(width: 12),
                  Text('EDIT DATA'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 12),
                  Text('DELETE ENTRY'),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showAddEditDialog({Organization? org}) {
    final isEditing = org != null;
    final nameController = TextEditingController(text: org?.name ?? '');
    final descController = TextEditingController(text: org?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: electricGrid.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.add_circle_outline, color: electricGrid),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? "UPDATE ENTRY" : "NEW ORGANIZATION",
                    style: const TextStyle(
                      color: paperWhite,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              
              _buildTechTextField("NAME", nameController),
              const SizedBox(height: 16),
              _buildTechTextField("DESCRIPTION", descController),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: electricGrid,
                      foregroundColor: deepVoidBlue,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;

                      if (isEditing) {
                        final useCase = ref.read(updateOrganizationUseCaseProvider);
                        await useCase(UpdateOrganizationParams(
                          org.id,
                          nameController.text.trim(),
                          descController.text.trim(),
                        ));
                      } else {
                        final addOrgUseCase = ref.read(addOrganizationUseCaseProvider);
                        await addOrgUseCase(AddOrganizationParams(
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                        ));
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {}); // Refresh list
                      }
                    },
                    child: Text(isEditing ? "SAVE CHANGES" : "CREATE"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Organization org) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                "CONFIRM DELETION",
                style: TextStyle(color: paperWhite, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${org.name}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: paperWhite,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () async {
                      final useCase = ref.read(deleteOrganizationUseCaseProvider);
                      await useCase(org.id);
                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    child: const Text("DELETE PERMANENTLY"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: electricGrid,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: paperWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricGrid.withOpacity(0.3)),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: electricGrid),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// --- REUSED PAINTER ---
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
        paint
      );
    }
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + shift % gridSize), 
        Offset(size.width, y + shift % gridSize), 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) => true;
}