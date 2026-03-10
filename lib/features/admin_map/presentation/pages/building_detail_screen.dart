import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecases/admin_map_usecases.dart';
import '../../domain/entities/map_entities.dart';
import '../../domain/usecases/manage_floors_usecase.dart';
import '../providers/admin_map_providers.dart';
// --- IMPORT AUTH CONTROLLER ---
// --- IMPORT AUTH CONTROLLER ---
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/widgets/custom_toast.dart';

// Family provider
final floorsProvider = FutureProvider.family<List<Floor>, String>((
  ref,
  buildingId,
) async {
  final getFloorsUseCase = ref.read(getFloorsUseCaseProvider);
  final result = await getFloorsUseCase(buildingId);
  return result.fold((failure) => throw failure.message, (floors) => floors);
});

class BuildingDetailScreen extends ConsumerStatefulWidget {
  final String buildingId;
  final String buildingName;

  const BuildingDetailScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
  });

  @override
  ConsumerState<BuildingDetailScreen> createState() =>
      _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends ConsumerState<BuildingDetailScreen>
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
    final floorsAsync = ref.watch(floorsProvider(widget.buildingId));

    return Scaffold(
      backgroundColor: deepVoidBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'BUILDING CONFIGURATION',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 10,
                color: electricGrid,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.buildingName.toUpperCase(),
              style: const TextStyle(
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
        // --- ADDED LOGOUT ACTION HERE ---
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            tooltip: 'TERMINATE SESSION',
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
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: electricGrid.withOpacity(0.2), height: 1.0),
        ),
      ),
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
            child: floorsAsync.when(
              data: (floors) => floors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear_outlined,
                            size: 64,
                            color: electricGrid.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NO FLOORS DETECTED',
                            style: TextStyle(
                              color: paperWhite.withOpacity(0.5),
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: floors.length,
                      itemBuilder: (context, index) {
                        final floor = floors[index];
                        return _buildFloorCard(floor);
                      },
                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFloorDialog(context, ref),
        label: const Text(
          'ADD FLOOR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        icon: const Icon(Icons.post_add),
        backgroundColor: electricGrid,
        foregroundColor: deepVoidBlue,
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildFloorCard(Floor floor) {
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
          child: Text(
            "${floor.floorNumber}",
            style: const TextStyle(
              color: electricGrid,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          floor.name.toUpperCase(),
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
            "TAP TO EDIT LAYOUT // MANAGE ROOMS",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          ),
        ),
        onTap: () {
          final params = GoRouterState.of(context).pathParameters;
          final orgId = params['orgId'];

          if (orgId != null) {
            context.pushNamed(
              'floor_detail',
              pathParameters: {
                'orgId': orgId,
                'buildingId': widget.buildingId,
                'floorId': floor.id,
              },
              extra: floor.name,
            );
          } else {
            context.push('/floor/${floor.id}', extra: floor.name);
          }
        },
        trailing: _buildPopupMenu(floor),
      ),
    );
  }

  Widget _buildPopupMenu(Floor floor) {
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
            _showEditFloorDialog(context, ref, floor);
          } else if (value == 'delete') {
            _confirmDeleteFloor(context, ref, floor);
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
                Text('DELETE LAYER'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS (Tech Styled) ---

  void _showAddFloorDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    _showTechDialog(
      title: "ADD NEW FLOOR",
      icon: Icons.post_add,
      content: Column(
        children: [
          _buildTechTextField(
            "FLOOR NUMBER (INT)",
            numberController,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          _buildTechTextField("FLOOR NAME / LABEL", nameController),
        ],
      ),
      confirmLabel: "INITIALIZE",
      onConfirm: () async {
        final number = int.tryParse(numberController.text.trim());
        if (number == null) {
          _showSnackBar(context, 'INVALID NUMBER FORMAT', isError: true);
          return;
        }

        Navigator.pop(context);

        final useCase = ref.read(addFloorUseCaseProvider);
        final result = await useCase(
          AddFloorParams(widget.buildingId, number, nameController.text.trim()),
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
            if (context.mounted) _showSnackBar(context, 'FLOOR INITIALIZED');
            ref.invalidate(floorsProvider(widget.buildingId));
          },
        );
      },
    );
  }

  void _showEditFloorDialog(BuildContext context, WidgetRef ref, Floor floor) {
    final nameController = TextEditingController(text: floor.name);
    final numberController = TextEditingController(
      text: floor.floorNumber.toString(),
    );

    _showTechDialog(
      title: "EDIT FLOOR DATA",
      icon: Icons.edit_note,
      content: Column(
        children: [
          _buildTechTextField(
            "FLOOR NUMBER (INT)",
            numberController,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          _buildTechTextField("FLOOR NAME / LABEL", nameController),
        ],
      ),
      confirmLabel: "UPDATE",
      onConfirm: () async {
        final number = int.tryParse(numberController.text.trim());
        if (number == null) {
          _showSnackBar(context, 'INVALID NUMBER FORMAT', isError: true);
          return;
        }

        Navigator.pop(context);
        final useCase = ref.read(updateFloorUseCaseProvider);
        final result = await useCase(
          UpdateFloorParams(
            widget.buildingId,
            floor.id,
            number,
            nameController.text.trim(),
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
            ref.invalidate(floorsProvider(widget.buildingId));
          },
        );
      },
    );
  }

  void _confirmDeleteFloor(BuildContext context, WidgetRef ref, Floor floor) {
    _showTechDialog(
      title: "CONFIRM DELETION",
      icon: Icons.warning_amber_rounded,
      isDanger: true,
      content: Text(
        'Delete floor "${floor.name}"?\nWARNING: All rooms and layout data will be purged.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      confirmLabel: "PERMANENTLY DELETE",
      onConfirm: () async {
        Navigator.pop(context);
        final useCase = ref.read(deleteFloorUseCaseProvider);
        final result = await useCase(
          DeleteFloorParams(widget.buildingId, floor.id),
        );

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
            if (context.mounted) _showSnackBar(context, 'LAYER PURGED');
            ref.invalidate(floorsProvider(widget.buildingId));
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

  Widget _buildTechTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
    if (!mounted) return;
    ToastService.show(context, message, isError: isError);
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
