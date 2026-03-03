import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/admin_login_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/navigation/presentation/pages/user_home_screen.dart';
import '../../features/admin_map/presentation/pages/admin_dashboard_screen.dart';
import '../../features/admin_map/presentation/pages/building_detail_screen.dart';
import '../../features/admin_map/presentation/pages/floor_detail_screen.dart';
import '../../features/admin_map/presentation/pages/user_management_screen.dart';
import '../../features/admin_map/presentation/pages/campus_connections_screen.dart';
import '../../features/admin_map/presentation/pages/organization_list_screen.dart'; // Added
import '../../features/ar_navigation/presentation/pages/ar_navigation_screen.dart';
import '../widgets/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userProfileAsync = ref.watch(userProfileProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const UserHomeScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const OrganizationListScreen(), // New Entry Point
        routes: [
          GoRoute(
            path: 'dashboard/:orgId',
            builder: (context, state) {
              final orgId = state.pathParameters['orgId'];
              return AdminDashboardScreen(organizationId: orgId);
            },
            routes: [
              GoRoute(
                path: 'building/:buildingId',
                builder: (context, state) {
                  final buildingId = state.pathParameters['buildingId']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  return BuildingDetailScreen(
                    buildingId: buildingId,
                    buildingName: extra?['name'] ?? 'Building Details',
                  );
                },
                routes: [
                  GoRoute(
                    name: 'floor_detail',
                    path: 'floor/:floorId',
                    builder: (context, state) {
                      final buildingId = state.pathParameters['buildingId']!;
                      final floorId = state.pathParameters['floorId']!;
                      String floorName = 'Floor Details';
                      if (state.extra is Map) {
                        floorName =
                            (state.extra as Map)['floorName'] ??
                            'Floor Details';
                      } else if (state.extra is String) {
                        floorName = state.extra as String;
                      }
                      return FloorDetailScreen(
                        buildingId: buildingId,
                        floorId: floorId,
                        floorName: floorName,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'users',
                builder: (context, state) => const UserManagementScreen(),
              ),
              GoRoute(
                path: 'connections',
                builder: (context, state) => const CampusConnectionsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/ar-navigation',
        builder: (context, state) => const ArNavigationScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';
      final isAdminLoggingIn = state.uri.toString() == '/admin/login';
      final isSplash = state.uri.toString() == '/splash';

      final isGoingToAdmin =
          state.uri.toString().startsWith('/admin') && !isAdminLoggingIn;

      // 1. If not logged in, force login (unless already there)
      if (!isLoggedIn) {
        if (isGoingToAdmin) return '/admin/login';
        if (!isLoggingIn && !isSigningUp && !isAdminLoggingIn) return '/login';
        return null;
      }

      // 2. Logged in, but profile is still loading? -> Splash
      final user = ref.read(currentUserProvider);

      // If user is logged in (Auth Object exists) but Profile (Firestore doc) is not loaded yet
      // Check if the AsyncValue is loading or has no data
      if (userProfileAsync.isLoading ||
          (user == null && !userProfileAsync.hasError)) {
        if (!isSplash) return '/splash';
        return null;
      }

      // 3. Profile Loaded. Redirect from splash/login pages to dashboard
      if (isSplash || isLoggingIn || isSigningUp || isAdminLoggingIn) {
        if (user?.role == UserRole.admin) return '/admin';
        return '/';
      }

      // 4. Access Control for Admin Routes
      if (isGoingToAdmin) {
        if (user?.role != UserRole.admin) {
          return '/';
        }
      }

      // 5. Force Admin to Admin Dashboard if at root
      // 5. Force Admin to Admin Dashboard if at root
      if (state.uri.toString() == '/') {
        if (user?.role == UserRole.admin) {
          return '/admin';
        }
      }

      return null;
    },
  );
});
