import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

import 'providers/app_state.dart';

import 'services/backend_config.dart';

import 'services/firebase_service.dart';

import 'services/notification_service.dart';

import 'services/plan_agent_service.dart';

import 'services/subscription_service.dart';

import 'services/supabase_service.dart';

import 'services/sync_service.dart';

import 'theme/app_theme.dart';

import 'config/release_config.dart';
import 'screens/config_error_screen.dart';
import 'screens/login_screen.dart';

import 'screens/onboarding_screen.dart';

import 'screens/home_screen.dart';

import 'screens/chat_screen.dart';

import 'screens/workout_screen.dart';

import 'screens/meals_screen.dart';

import 'screens/profile/profile_screen.dart';
import 'widgets/page_transitions.dart';
import 'widgets/location_permission_sheet.dart';

import 'screens/progress_screen.dart';

import 'screens/feed_screen.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');



  if (BackendConfig.hasFirebase) {

    final options = DefaultFirebaseOptions.currentPlatform;

    if (options != null) {

      await Firebase.initializeApp(options: options);

      await FirebaseService.enableOfflineSync();

      if (kReleaseMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

    }

    if (FirebaseService.currentUser != null) {

      PlanAgentService.generateWeeklyPlanIfNeeded();

    }

  }



  if (BackendConfig.hasSupabase) {

    await Supabase.initialize(

      url: BackendConfig.supabaseUrl!,

      anonKey: BackendConfig.supabaseAnonKey!,

    );

    if (!BackendConfig.hasFirebase && SupabaseService.currentUser != null) {

      PlanAgentService.generateWeeklyPlanIfNeeded();

    }

  }



  await SubscriptionService.init();

  await NotificationService.init();

  await SyncService.startListening();



  applySystemChrome(ThemeMode.system, WidgetsBinding.instance.platformDispatcher.platformBrightness);

  runApp(
    const ProviderScope(
      child: GymCompanionApp(),
    ),
  );

}



class GymCompanionApp extends ConsumerWidget {

  const GymCompanionApp({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    applySystemChrome(themeMode, platformBrightness);

    return provider.ChangeNotifierProvider(

      create: (_) => AppState()..init(),

      child: provider.Consumer<AppState>(

        builder: (_, state, __) {
          return MaterialApp(

            title: 'Gym Companion',

            debugShowCheckedModeBanner: false,

            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,

            themeAnimationDuration: const Duration(milliseconds: 400),

            themeAnimationCurve: Curves.easeInOutCubic,

            home: !ReleaseConfig.isProductionReady
                ? const ConfigErrorScreen()
                : state.loading

                ? const _Splash()

                : state.session == null

                    ? const LoginScreen()

                    : state.user?.profileComplete != true

                        ? const OnboardingScreen()

                        : const MainShell(),

          );

        },

      ),

    );

  }

}



class _Splash extends StatelessWidget {
  const _Splash();

  static const _splashBg = Color(0xFF111C22);
  static const _splashText = Color(0xFFE8F0F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3D7A93), Color(0xFF7FB5A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _splashText.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.auto_awesome, color: _splashText, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gym Companion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _splashText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered fitness coach',
                style: TextStyle(color: _splashText.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _splashText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class MainShell extends ConsumerStatefulWidget {

  const MainShell({super.key});



  static const _tabs = [
    (id: 'tab-home', icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (id: 'tab-workout', icon: Icons.local_fire_department_outlined, active: Icons.local_fire_department, label: 'Workout'),
    (id: 'tab-meals', icon: Icons.restaurant_outlined, active: Icons.restaurant, label: 'Food'),
    (id: 'tab-progress', icon: Icons.show_chart_outlined, active: Icons.show_chart, label: 'Progress'),
    (id: 'tab-chat', icon: Icons.chat_bubble_outline, active: Icons.chat_bubble, label: 'Coach'),
    (id: 'tab-feed', icon: Icons.newspaper_outlined, active: Icons.newspaper, label: 'Feed'),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _locationSheetShown = false;

  @override

  Widget build(BuildContext context) {

    final state = provider.Provider.of<AppState>(context);
    if (state.shouldShowLocationPrompt && !_locationSheetShown) {
      _locationSheetShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        LocationPermissionSheet.show(context);
      });
    }
    final themeMode = ref.watch(themeModeProvider);
    final isDark = resolveIsDark(
      themeMode,
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    final theme = context.appTheme;
    final colors = context.appColors;
    final onHome = state.tabIndex == 0;
    final tabTitle = MainShell._tabs[state.tabIndex].label;

    return PopScope(
      canPop: state.tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.tabIndex != 0) state.setTab(0);
      },
      child: Scaffold(
      backgroundColor: theme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: onHome
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                identifier: 'app-title',
                                child: Text(tabTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: theme.textPrimary, letterSpacing: -0.2)),
                              ),
                              Semantics(
                                identifier: 'app-subtitle',
                                label: '${state.displayName ?? ""} ${state.user!.weeklyPlan.macros["calories"] ?? state.user!.tdee} kcal target',
                                child: Text(
                                  '${state.displayName ?? ""} · ${state.user!.weeklyPlan.macros["calories"] ?? state.user!.tdee} kcal',
                                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: theme.iconMuted,
                      size: 22,
                    ),
                  ),
                  Semantics(
                    identifier: 'logout-btn',
                    button: true,
                    child: IconButton(
                      onPressed: () => state.logout(),
                      icon: Icon(Icons.logout, color: theme.iconMuted, size: 22),
                      tooltip: 'Logout',
                    ),
                  ),
                  Semantics(
                    identifier: 'tab-profile',
                    button: true,
                    child: GestureDetector(
                      onTap: () => pushPremium(context, const ProfileScreen()),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        child: Text(
                          (state.displayName ?? 'A').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? colors.dusk : colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: state.tabIndex,
                children: [
                  const HomeScreen(),
                  const WorkoutScreen(),
                  const MealsScreen(),
                  const ProgressScreen(),
                  ChatScreen(embedded: true, onNavigate: state.setTab),
                  const FeedScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: theme.navBar,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderSubtle),
            boxShadow: theme.cardShadow,
          ),
          child: Row(
            children: List.generate(MainShell._tabs.length, (i) {
              final tab = MainShell._tabs[i];
              final active = state.tabIndex == i;
              final narrow = MediaQuery.sizeOf(context).width < 360;
              return Expanded(
                child: Semantics(
                  identifier: tab.id,
                  button: true,
                  label: tab.label,
                  child: GestureDetector(
                    onTap: () => state.setTab(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? colors.primaryTintBg : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(active ? tab.active : tab.icon, size: 22, color: active ? colors.primary : theme.navInactive),
                          if (active || narrow) ...[
                            const SizedBox(height: 2),
                            Text(
                              narrow && !active ? tab.label.substring(0, 1) : tab.label,
                              style: TextStyle(fontSize: narrow && !active ? 8 : 9, fontWeight: FontWeight.w500, color: active ? colors.primary : theme.navInactive),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
    );

  }

}


