import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';

class LocationSearchDialog extends ConsumerStatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  ConsumerState<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends ConsumerState<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Room> _results = [];
  bool _searching = false;

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _searching = true);

    // Get all rooms from Graph Service (assuming it's loaded)
    // If not loaded, we might need to rely on cached data or trigger a load.
    // Ideally, GraphService should have all rooms loaded if we are on UserHome.
    final graphService = ref.read(graphServiceProvider);
    
    // Simple local search
    final allRooms = graphService.allRooms; 
    
    final matches = allRooms.where((room) {
      return room.name.toLowerCase().contains(query.toLowerCase()) && 
             room.type != RoomType.hallway; // Exclude hallways
    }).toList();

    setState(() {
      _results = matches;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search room, building...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            if (_searching)
              const LinearProgressIndicator()
            else if (_results.isEmpty && _searchController.text.isNotEmpty)
               const Text('No results found'),
            
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final room = _results[index];
                  // We need building info. Since room only has floorId, lookup might be needed.
                  // For now, display Room Name and Floor ID (or floor number/name if available)
                  
                  return ListTile(
                    leading: Icon(
                      room.type == RoomType.elevator ? Icons.elevator : 
                      (room.type == RoomType.stairs ? Icons.stairs : Icons.place),
                      color: Colors.indigo,
                    ),
                    title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${room.id}'), // Placeholder for "Building A, Floor 1"
                    onTap: () {
                      Navigator.pop(context, room);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
