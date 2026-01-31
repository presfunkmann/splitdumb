import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/features/auth/presentation/sign_in_screen.dart';
import 'package:splitdumb/features/auth/presentation/sign_up_screen.dart';
import 'package:splitdumb/features/auth/presentation/splash_screen.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/balances/presentation/group_balances_screen.dart';
import 'package:splitdumb/features/expenses/presentation/add_expense_screen.dart';
import 'package:splitdumb/features/expenses/presentation/expense_detail_screen.dart';
import 'package:splitdumb/features/groups/presentation/create_group_screen.dart';
import 'package:splitdumb/features/groups/presentation/group_detail_screen.dart';
import 'package:splitdumb/features/groups/presentation/group_settings_screen.dart';
import 'package:splitdumb/features/groups/presentation/groups_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';

      // Show splash while loading
      if (isLoading) {
        return '/splash';
      }

      // Redirect to sign-in if not logged in
      if (!isLoggedIn && !isAuthRoute) {
        return '/sign-in';
      }

      // Redirect to home if logged in and on auth route
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      // Redirect away from splash once loaded
      if (!isLoading && state.matchedLocation == '/splash') {
        return isLoggedIn ? '/' : '/sign-in';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const GroupsListScreen(),
        routes: [
          GoRoute(
            path: 'groups/create',
            builder: (context, state) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: 'groups/:groupId',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return GroupDetailScreen(groupId: groupId);
            },
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return GroupSettingsScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'balances',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return GroupBalancesScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'expenses/add',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return AddExpenseScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'expenses/:expenseId',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  final expenseId = state.pathParameters['expenseId']!;
                  return ExpenseDetailScreen(
                    groupId: groupId,
                    expenseId: expenseId,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final expenseId = state.pathParameters['expenseId']!;
                      return AddExpenseScreen(
                        groupId: groupId,
                        expenseId: expenseId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
