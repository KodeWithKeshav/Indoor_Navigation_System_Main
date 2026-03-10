import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';

class LocationSearchDialog extends ConsumerStatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  ConsumerState<LocationSearchDialog> createState() =>
      _LocationSearchDialogState();
}

class _LocationSearchDialogState extends ConsumerState<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Room> _searchResults = [];
  bool _searching = false;
  String _query = '';

  void _search(String query) async {
    setState(() {
      _query = query;
    });

    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    // Get all rooms from Graph Service (assuming it's loaded)
    final graphService = ref.read(graphServiceProvider);

    // Simple local search
    final allRooms = graphService.allRooms;

    final matches = allRooms.where((room) {
      return room.name.toLowerCase().contains(query.toLowerCase()) &&
          room.type != RoomType.hallway &&
          room.type != RoomType.elevator &&
          room.type != RoomType.stairs; // Filter out transit nodes
    }).toList();

    setState(() {
      _searchResults = matches;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B), // Dark Card Color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 600,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search room, or browse below...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF38BDF8),
                ), // Electric Grid
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _query.isEmpty
                  ? _buildBrowseHierarchy()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty)
      return const Center(
        child: Text('No results found', style: TextStyle(color: Colors.grey)),
      );

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final room = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.place, color: Color(0xFF38BDF8)),
          title: Text(
            room.isClosed ? '${room.name} (Closed)' : room.name,
            style: TextStyle(
              color: room.isClosed ? Colors.grey : Colors.white,
              fontWeight: FontWeight.bold,
              decoration: room.isClosed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            room.isClosed
                ? 'Currently Out of Service'
                : 'Floor: ${room.floorId}',
            style: TextStyle(
              color: room.isClosed
                  ? Colors.redAccent
                  : Colors.white.withOpacity(0.6),
            ),
          ),
          onTap: room.isClosed
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${room.name} is currently out of service.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              : () => Navigator.pop(context, room),
        );
      },
    );
  }

  Widget _buildBrowseHierarchy() {
    final user = ref.watch(currentUserProvider);
    final buildingsAsync = ref.watch(buildingsProvider(user?.organizationId));

    return buildingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (buildings) {
        // Filter out buildings without floors/rooms if needed, or just show list
        // Also include Campus "building" if relevant, but maybe just stick to physical buildings for browse mode

        if (buildings.isEmpty)
          return const Center(
            child: Text(
              'No buildings available.',
              style: TextStyle(color: Colors.grey),
            ),
          );

        return ListView.builder(
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return _BuildingExpansionTile(building: building);
          },
        );
      },
    );
  }
}

class _BuildingExpansionTile extends ConsumerWidget {
  final Building building;
  const _BuildingExpansionTile({required this.building});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only fetch floors if we expand? ExpansionTile doesn't support lazy loading efficiently without state.
    // We'll watch floors immediately.
    final floorsAsync = ref.watch(floorsOfBuildingProvider(building.id));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.apartment, color: Color(0xFF38BDF8)),
        title: Text(
          building.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16),
        collapsedIconColor: Colors.white54,
        iconColor: const Color(0xFF38BDF8),
        children: [
          floorsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Err: $e',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            data: (floors) {
              if (floors.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No floors.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              return Column(
                children: floors
                    .map((floor) => _FloorExpansionTile(floor: floor))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FloorExpansionTile extends ConsumerWidget {
  final Floor floor;
  const _FloorExpansionTile({required this.floor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rooms are filtered from Graph Service
    final graphService = ref.read(graphServiceProvider);

    // We get rooms from synchronous graph service for speed.
    // If graph service isn't initialized, this might be empty.
    // The graph service is usually initialized on app start.

    final rooms = graphService.allRooms
        .where(
          (r) =>
              r.floorId == floor.id &&
              r.type != RoomType.hallway &&
              r.type != RoomType.elevator &&
              r.type != RoomType.stairs,
        )
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.layers, color: Colors.white70, size: 20),
        title: Text(floor.name, style: const TextStyle(color: Colors.white70)),
        childrenPadding: const EdgeInsets.only(left: 16),
        collapsedIconColor: Colors.white54,
        iconColor: Colors.white,
        children: [
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "No rooms listed.",
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            )
          else
            ...rooms.map(
              (room) => ListTile(
                leading: Icon(
                  Icons.meeting_room,
                  color: room.isClosed
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white54,
                  size: 18,
                ),
                title: Text(
                  room.isClosed ? '${room.name} (Closed)' : room.name,
                  style: TextStyle(
                    color: room.isClosed ? Colors.grey : Colors.white60,
                    decoration: room.isClosed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                dense: true,
                onTap: room.isClosed
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${room.name} is currently out of service.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    : () => Navigator.pop(context, room),
              ),
            ),
        ],
      ),
    );
  }
}
