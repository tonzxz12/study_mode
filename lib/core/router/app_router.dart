import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/planner/planner_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../navigation/main_navigation_curved.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/timer',
          name: 'timer',
          builder: (context, state) => const TimerScreen(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/planner',
          name: 'planner',
          builder: (context, state) => const PlannerScreen(),
        ),
      ],
    ),
  ],
);
