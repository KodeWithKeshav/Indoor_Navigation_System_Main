import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// The main landing page for the navigation context.
///
/// Currently serves as a basic entry point with access to the Admin Dashboard
/// and logout functionality.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indoor Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authRepositoryProvider).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home Screen - Navigation Context'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.push('/admin');
              },
              child: const Text('Go to Admin Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
