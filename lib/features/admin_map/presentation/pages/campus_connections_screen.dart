import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_map_providers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/manage_campus_usecase.dart';
import '../../domain/usecases/admin_map_usecases.dart'; // Added
import '../../../auth/presentation/providers/auth_providers.dart'; // Added for currentUserProvider

class CampusConnectionsScreen extends ConsumerStatefulWidget {
  const CampusConnectionsScreen({super.key});

  @override
  ConsumerState<CampusConnectionsScreen> createState() => _CampusConnectionsScreenState();
}

class _CampusConnectionsScreenState extends ConsumerState<CampusConnectionsScreen> {
  final _distanceController = TextEditingController();
  
  // Selections
  String? _fromBuildingId;
  String? _toBuildingId;

  @override
  Widget build(BuildContext context) {
    // We should use a provider that combines these or just multiple watches.
    // Better: Use the stream/future providers if defined, or define ad-hoc.
    // But since usecases return Either, we handle valid data.

    // 1. Fetch Buildings
    // We'll reuse the buildingsProvider(null) if it exists or create one.
    // Actually `buildingsProvider` exists in admin_map_providers.
    final buildingsAsync = ref.watch(buildingsProvider(null)); // null org for all/campus? 
    // Wait, getBuildingsUseCase takes orgId. If null, does it return all? 
    // Usually admin sees all for their org. Let's assume passed orgId or null means global?
    // Actually CampusConnectionsScreen is likely used in context of an Org.
    // But here we don't have orgId in params. Let's assume user provider has it.
    
    final user = ref.watch(currentUserProvider);
    final orgId = user?.organizationId;
    
    final realBuildingsAsync = ref.watch(buildingsProvider(orgId));
    final connectionsAsync = ref.watch(campusConnectionsProvider); 

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Connections')),
      body: realBuildingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading buildings: $e')),
        data: (buildings) {
          return connectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading connections: $e')),
            data: (connections) {
                 // Helper to get name
                  String getBldgName(String id) {
                     try {
                        return buildings.firstWhere((b) => b.id == id).name;
                     } catch (_) { return id; }
                  }
                  
                  return Column(
                    children: [
                      // --- Add New Connection Form ---
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Link Buildings', style: TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'From'),
                                      value: _fromBuildingId,
                                      items: buildings.map((b) {
                                        return DropdownMenuItem(value: b.id, child: Text(b.name));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _fromBuildingId = val),
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.swap_horiz)),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'To'),
                                      value: _toBuildingId,
                                      // Filter to avoid self-select? 
                                      items: buildings.map((b) {
                                        return DropdownMenuItem(value: b.id, child: Text(b.name));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _toBuildingId = val),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _distanceController,
                                decoration: const InputDecoration(labelText: 'Distance (meters)', helperText: 'Approximate walking distance'),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: (_fromBuildingId == null || _toBuildingId == null) 
                                  ? null 
                                  : () async {
                                      final dist = double.tryParse(_distanceController.text) ?? 50.0;
                                      if (_fromBuildingId == _toBuildingId) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select different buildings')));
                                        return;
                                      }
                                      
                                      // Call UseCase
                                      final useCase = ref.read(addCampusConnectionUseCaseProvider);
                                      final result = await useCase(AddCampusConnectionParams(_fromBuildingId!, _toBuildingId!, dist));
                                      
                                      result.fold(
                                        (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}'))),
                                        (_) {
                                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection Added')));
                                            setState(() {
                                              _distanceController.clear();
                                              _fromBuildingId = null;
                                              _toBuildingId = null;
                                            });
                                            // Refresh List
                                            ref.invalidate(campusConnectionsProvider);
                                        }
                                      );
                                    },
                                child: const Text('Add Connection'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Divider(),
                      
                      // --- List of Connections ---
                      Expanded(
                        child: connections.isEmpty 
                           ? const Center(child: Text("No connections yet."))
                           : ListView.builder(
                          itemCount: connections.length,
                          itemBuilder: (context, index) {
                            final conn = connections[index];
                            return ListTile(
                              leading: const Icon(Icons.timeline),
                              title: Text('${getBldgName(conn.fromBuildingId)}  ⟷  ${getBldgName(conn.toBuildingId)}'),
                              subtitle: Text('${conn.distance.toStringAsFixed(1)} meters'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final useCase = ref.read(deleteCampusConnectionUseCaseProvider);
                                  await useCase(conn.id);
                                  ref.invalidate(campusConnectionsProvider);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
            },
          );
        },
      ),
    );
  }
}
