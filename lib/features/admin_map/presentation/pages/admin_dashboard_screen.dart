import 'dart:ui';
import '../../../../core/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecases/admin_map_usecases.dart';
import '../../domain/usecases/manage_buildings_usecase.dart';
import '../../domain/entities/map_entities.dart';
import '../providers/admin_map_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final String? organizationId;
  const AdminDashboardScreen({super.key, this.organizationId});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
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
    final buildingsAsync = ref.watch(buildingsProvider(widget.organizationId));

    return Scaffold(
      backgroundColor: deepVoidBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'CAMPUS MAP EDITOR',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: deepVoidBlue.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: electricGrid),
        titleTextStyle: const TextStyle(color: paperWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: darkCardColor,
                  title: const Text(
                    'Confirm Logout',
                    style: TextStyle(color: electricGrid),
                  ),
                  content: const Text(
                    'Are you sure you want to terminate your session?',
                    style: TextStyle(color: paperWhite),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref
                            .read(authControllerProvider.notifier)
                            .logout(context);
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: electricGrid.withOpacity(0.2), height: 1.0),
        ),
      ),
      drawer: AdminDrawer(organizationId: widget.organizationId),
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
            child: buildingsAsync.when(
              data: (buildings) {
                if (buildings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: electricGrid.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NO STRUCTURES DETECTED',
                          style: TextStyle(
                            color: paperWhite.withOpacity(0.5),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTechButton(
                          label: "INITIALIZE FIRST BUILDING",
                          icon: Icons.add_business_outlined,
                          onPressed: () => _showAddBuildingDialog(context, ref),
                        ),
                        const SizedBox(height: 16),
                        // Global Map Option
                        if (widget.organizationId != null)
                          TextButton.icon(
                            onPressed: () => context.push(
                              '/admin/dashboard/${widget.organizationId}/building/campus_${widget.organizationId}/floor/ground',
                              extra: {'floorName': 'Campus Map (Outdoors)'},
                            ),
                            icon: const Icon(
                              Icons.map_outlined,
                              color: electricGrid,
                            ),
                            label: const Text(
                              "ACCESS GLOBAL OUTDOOR MAP",
                              style: TextStyle(
                                color: electricGrid,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buildings.length,
                  itemBuilder: (context, index) {
                    final building = buildings[index];
                    return _buildBuildingCard(building);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: electricGrid),
              ),
              error: (error, _) => Center(
                child: Text(
                  'SYSTEM ERROR: $error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'campus',
            backgroundColor: darkCardColor,
            foregroundColor: electricGrid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: electricGrid),
            ),
            onPressed: () => context.push(
              '/admin/dashboard/${widget.organizationId}/building/campus_${widget.organizationId}/floor/ground',
              extra: {'floorName': 'Campus Map (Outdoors)'},
            ),
            label: const Text(
              'GLOBAL MAP',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            icon: const Icon(Icons.map),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_bldg',
            backgroundColor: electricGrid,
            foregroundColor: deepVoidBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onPressed: () => _showAddBuildingDialog(context, ref),
            label: const Text(
              'NEW BUILDING',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTechButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricGrid,
        foregroundColor: deepVoidBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const RoundedRectangleBorder(),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBuildingCard(Building building) {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: electricGrid.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: electricGrid.withOpacity(0.3)),
          ),
          child: const Icon(Icons.business, color: electricGrid),
        ),
        title: Text(
          building.name.toUpperCase(),
          style: const TextStyle(
            color: paperWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            "STATUS: ACTIVE // TAP TO MANAGE FLOORS",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          ),
        ),
        onTap: () {
          context.push(
            '/admin/dashboard/${widget.organizationId}/building/${building.id}',
            extra: {'name': building.name},
          );
        },
        trailing: _buildPopupMenu(building),
      ),
    );
  }

  Widget _buildPopupMenu(Building building) {
    return Theme(
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
            _showEditBuildingDialog(context, ref, building);
          } else if (value == 'delete') {
            _confirmDeleteBuilding(context, ref, building);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: electricGrid, size: 18),
                SizedBox(width: 12),
                Text('EDIT METADATA'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                SizedBox(width: 12),
                Text('DELETE STRUCTURE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS (Tech Styled) ---

  void _showAddBuildingDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    _showTechDialog(
      title: "NEW BUILDING",
      icon: Icons.add_business,
      content: Column(
        children: [
          _buildTechTextField("BUILDING NAME", nameController),
          const SizedBox(height: 16),
          _buildTechTextField("DESCRIPTION / CODE", descController),
        ],
      ),
      confirmLabel: "INITIALIZE",
      onConfirm: () async {
        Navigator.pop(context);

        final useCase = ref.read(addBuildingUseCaseProvider);
        final result = await useCase(
          AddBuildingParams(
            nameController.text.trim(),
            descController.text.trim(),
            organizationId: widget.organizationId,
          ),
        );

        result.fold(
          (failure) {
            if (context.mounted)
              _showSnackBar(
                context,
                'ERROR: ${failure.message}',
                isError: true,
              );
          },
          (_) {
            if (context.mounted) _showSnackBar(context, 'BUILDING INITIALIZED');
            ref.invalidate(buildingsProvider(widget.organizationId));
          },
        );
      },
    );
  }

  void _showEditBuildingDialog(
    BuildContext context,
    WidgetRef ref,
    Building building,
  ) {
    final nameController = TextEditingController(text: building.name);
    final descController = TextEditingController(text: building.description);

    _showTechDialog(
      title: "EDIT METADATA",
      icon: Icons.edit_note,
      content: Column(
        children: [
          _buildTechTextField("BUILDING NAME", nameController),
          const SizedBox(height: 16),
          _buildTechTextField("DESCRIPTION / CODE", descController),
        ],
      ),
      confirmLabel: "UPDATE",
      onConfirm: () async {
        Navigator.pop(context);
        final useCase = ref.read(updateBuildingUseCaseProvider);
        final result = await useCase(
          UpdateBuildingParams(
            building.id,
            nameController.text.trim(),
            descController.text.trim(),
          ),
        );

        result.fold(
          (failure) {
            if (context.mounted)
              _showSnackBar(
                context,
                'UPDATE FAILED: ${failure.message}',
                isError: true,
              );
          },
          (_) {
            if (context.mounted) _showSnackBar(context, 'METADATA UPDATED');
            ref.invalidate(buildingsProvider);
          },
        );
      },
    );
  }

  void _confirmDeleteBuilding(
    BuildContext context,
    WidgetRef ref,
    Building building,
  ) {
    _showTechDialog(
      title: "CONFIRM DEMOLITION",
      icon: Icons.warning_amber_rounded,
      isDanger: true,
      content: Text(
        'Delete structure "${building.name}"?\nWARNING: All floors and rooms within will be purged.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      confirmLabel: "PERMANENTLY DELETE",
      onConfirm: () async {
        Navigator.pop(context);
        final useCase = ref.read(deleteBuildingUseCaseProvider);
        final result = await useCase(building.id);

        result.fold(
          (failure) {
            if (context.mounted)
              _showSnackBar(
                context,
                'DELETION FAILED: ${failure.message}',
                isError: true,
              );
          },
          (_) {
            if (context.mounted) _showSnackBar(context, 'STRUCTURE PURGED');
            ref.invalidate(buildingsProvider);
          },
        );
      },
    );
  }

  // --- HELPER FUNCTIONS ---

  void _showTechDialog({
    required String title,
    required IconData icon,
    required Widget content,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isDanger ? Colors.redAccent : electricGrid.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: isDanger ? Colors.redAccent : electricGrid),
                  const SizedBox(width: 12),
                  Text(
                    title,
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
              content,
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "ABORT",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDanger
                          ? Colors.redAccent
                          : electricGrid,
                      foregroundColor: isDanger ? paperWhite : deepVoidBlue,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: onConfirm,
                    child: Text(confirmLabel),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ToastService.show(context, message, isError: isError);
  }
}

// --- PAINTER (Standard) ---
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
