import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_models.dart';
import 'services/hospital_service.dart';
import 'services/local_notification_service.dart';
import 'services/supabase_backend_service.dart';

Route<T> _smoothPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(fade);
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}

class BloodApp extends StatelessWidget {
  const BloodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Plus+',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFFE53935);
  static const primaryDark = Color(0xFFB71C1C);
  static const primaryLight = Color(0xFFF4423B);
  static const accent = Color(0xFFFF8A80);
  static const background = Color(0xFFFAFAFA);
  static const surfaceVariant = Color(0xFFF5F5F5);
  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF616161);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final backend = SupabaseBackendService.instance;

    return StreamBuilder(
      stream: backend.authStateChanges,
      builder: (context, snapshot) {
        if (backend.currentUser != null) {
          return const AppShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _backend = SupabaseBackendService.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _backend.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException &&
          error.message.toLowerCase().contains('email not confirmed')) {
        _showSnack(context, 'Email not confirmed. Please verify your email first.');
        return;
      }
      _showSnack(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        height: 70,
                        width: 70,
                        decoration: const BoxDecoration(
                          color: Color(0x1AE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: BloodDropLogo(size: 44)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to find donors and respond quickly.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'Email address',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter your email';
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account? '),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                _smoothPageRoute(const SignUpScreen()),
                              );
                            },
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _backend = SupabaseBackendService.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _bloodGroup = 'A+';
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack(context, 'Password and Confirm Password must match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _backend.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        metadata: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'blood_group': _bloodGroup,
          'area': '',
        },
      );

      await _backend.signOut();

      if (!mounted) return;

      _showSnack(context, 'Signup successful. Please login.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                  validator: (value) =>
                      _isValidPhoneNumber(value ?? '') ? null : 'Enter a valid 10-digit mobile number',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _bloodGroup,
                  decoration: const InputDecoration(
                    hintText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                  ),
                  items: bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _bloodGroup = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be 6+ characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                      icon: Icon(_hideConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Confirm password must be 6+ characters';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading ? null : _signUp,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _backend = SupabaseBackendService.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _loadedTabs = {0};
  int _index = 0;
  bool _profilePromptShown = false;
  DateTime? _lastBackPressAt;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeProfileState());
  }

  Future<void> _initializeProfileState() async {
    await _backend.syncMyProfileFromAuthMetadata();
    await _maybePromptCompleteProfile();
  }

  Future<void> _maybePromptCompleteProfile() async {
    if (_profilePromptShown || !mounted) return;

    final profile = await _backend.fetchMyProfile();
    if (!mounted || profile == null) return;

    final needsAge = profile.age == null || profile.age! < 1;
    final needsGender = profile.gender.trim().isEmpty;
    if (!needsAge && !needsGender) return;

    _profilePromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Complete Profile Details'),
            content: const Text('Please add your age and gender in Profile details.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      _selectTab(4);
    });
  }

  void _selectTab(int index) {
    setState(() {
      _index = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onOpenTab: _selectTab);
      case 1:
        return const DonorListScreen();
      case 2:
        return const HospitalMapScreen();
      case 3:
        return const RequestBloodScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _goToIndex(int index) {
    _selectTab(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _handlePopAttempt() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).maybePop();
      return;
    }

    if (_index != 0) {
      _selectTab(0);
      return;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressAt != null && now.difference(_lastBackPressAt!) < const Duration(seconds: 2);
    if (shouldExit) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPressAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Press back again to exit app')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _backend.currentUser?.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handlePopAttempt());
      },
      child: NotificationSync(
        userId: userId,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(_navItems[_index].label),
            actions: [
              if (_index == 0 && userId != null)
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(_smoothPageRoute(const NotificationsPage()));
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
            ],
          ),
          drawerEnableOpenDragGesture: true,
          drawer: MainMenuDrawer(
            onOpenTab: _goToIndex,
            onOpenPage: (page) {
              final navigator = Navigator.of(context);
              _scaffoldKey.currentState?.closeDrawer();
              Future<void>.delayed(const Duration(milliseconds: 120), () {
                if (!mounted) return;
                navigator.push(_smoothPageRoute(page));
              });
            },
            onLogout: () async {
              _scaffoldKey.currentState?.closeDrawer();
              await _backend.signOut();
            },
          ),
          body: IndexedStack(
            index: _index,
            children: List<Widget>.generate(
              5,
              (tabIndex) => _loadedTabs.contains(tabIndex) ? _buildTab(tabIndex) : const SizedBox.shrink(),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            destinations: _navItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class MainMenuDrawer extends StatelessWidget {
  const MainMenuDrawer({
    super.key,
    required this.onOpenTab,
    required this.onOpenPage,
    required this.onLogout,
  });

  final ValueChanged<int> onOpenTab;
  final ValueChanged<Widget> onOpenPage;
  final VoidCallback onLogout;

  void _handleDrawerAction(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 80), action);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<DonorProfile?>(
              future: SupabaseBackendService.instance.fetchMyProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0x1AE53935),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: BloodDropLogo(size: 34),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile?.fullName ?? 'Blood Plus+ User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '${profile?.bloodGroup ?? '-'} Donor',
                        style: const TextStyle(color: AppTheme.primary),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  _menuTile(context, Icons.home_outlined, 'Home', () => onOpenTab(0)),
                  _menuTile(context, Icons.people_alt_outlined, 'Donors', () => onOpenTab(1)),
                  _menuTile(context, Icons.map_outlined, 'Hospital Map', () => onOpenTab(2)),
                  _menuTile(context, Icons.bloodtype_outlined, 'Request Blood', () => onOpenTab(3)),
                  _menuTile(context, Icons.person_outline, 'Profile', () => onOpenTab(4)),
                  const Divider(height: 20),
                  _menuTile(
                    context,
                    Icons.notifications_none,
                    'Notifications',
                    () => onOpenPage(const NotificationsPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.menu_book_outlined,
                    'Donor Guidelines',
                    () => onOpenPage(const DonateBloodGuidelinesPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.info_outline,
                    'About App',
                    () => onOpenPage(const AboutPage()),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _handleDrawerAction(context, onLogout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => _handleDrawerAction(context, onTap),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final updatedTime = TimeOfDay.fromDateTime(DateTime.now()).format(context);
    return Container(
      color: const Color(0xFFECEFF1),
      child: Column(
        children: [
          Expanded(
            flex: 44,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  const BloodDropLogo(size: 110),
                  const SizedBox(height: 18),
                  const Text(
                    "GIVE'S THE GOLDEN OF LIFE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'serif',
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 2, color: AppTheme.primary.withValues(alpha: 0.18)),
                      Container(
                        color: const Color(0xFFECEFF1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          'Every drop will save a life.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryDark.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last Updated On : $updatedTime',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 56,
            child: ClipPath(
              clipper: _HomeWaveClipper(),
              child: Container(
                width: double.infinity,
                color: AppTheme.accent.withValues(alpha: 0.65),
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ActionCard(
                              title: 'Find a Donor',
                              icon: Icons.search,
                              badge: '235K',
                              onTap: () => onOpenTab(1),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ActionCard(
                              title: 'Blood Request',
                              icon: Icons.notifications_none,
                              badge: '500K',
                              onTap: () => onOpenTab(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ActionCard(
                              title: 'Blood Bank',
                              icon: Icons.water_drop_outlined,
                              badge: 'Map',
                              onTap: () => onOpenTab(2),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ActionCard(
                              title: 'Other',
                              icon: Icons.settings_outlined,
                              badge: 'More',
                              onTap: () => onOpenTab(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceVariant,
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 26),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontFamily: 'serif',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWaveClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width * 0.16, 0, size.width * 0.35, 32);
    path.quadraticBezierTo(size.width * 0.48, 54, size.width * 0.62, 30);
    path.quadraticBezierTo(size.width * 0.8, 0, size.width, 38);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final _backend = SupabaseBackendService.instance;

  List<DonorProfile> _allDonors = [];
  bool _loading = true;
  bool _availableOnly = true;
  String _query = '';
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDonors());
  }

  Future<void> _loadDonors() async {
    setState(() => _loading = true);
    try {
      final donors = await _backend.fetchDonors(availableOnly: _availableOnly);
      if (!mounted) return;
      setState(() {
        _allDonors = donors;
        if (_selectedBloodGroup != null &&
            !_allDonors.any((donor) => donor.bloodGroup == _selectedBloodGroup)) {
          _selectedBloodGroup = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _visibleBloodGroups {
    final registeredGroups = _allDonors
        .map((donor) => donor.bloodGroup)
        .where((group) => group.trim().isNotEmpty)
        .toSet();
    return bloodGroups.where(registeredGroups.contains).toList();
  }

  List<DonorProfile> get _filtered {
    return _allDonors.where((donor) {
      final search = _query.toLowerCase();
      final matchesArea = donor.area.toLowerCase().contains(search);
      final matchesBloodGroup =
          _selectedBloodGroup == null || donor.bloodGroup == _selectedBloodGroup;
      return matchesArea && matchesBloodGroup;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available donors only'),
            value: _availableOnly,
            onChanged: (value) {
              setState(() => _availableOnly = value);
              unawaited(_loadDonors());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by area',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedBloodGroup == null,
                    onSelected: (_) => setState(() => _selectedBloodGroup = null),
                  ),
                  ..._visibleBloodGroups.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(group),
                        selected: _selectedBloodGroup == group,
                        onSelected: (_) => setState(() => _selectedBloodGroup = group),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDonors,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, index) {
                      final donor = _filtered[index];
                      return DonorCard(donor: donor);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class DonorCard extends StatelessWidget {
  const DonorCard({super.key, required this.donor});

  final DonorProfile donor;

  Future<void> _callDonor(BuildContext context) async {
    final number = donor.phone.trim();
    if (number.isEmpty) {
      _showSnack(context, 'This donor has no phone number.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showSnack(context, 'Could not open phone dialer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _callDonor(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    donor.bloodGroup,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${donor.area} • ${donor.phone}${donor.available ? '' : ' • Not available'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: AppTheme.primary, size: 20),
                  onPressed: () => _callDonor(context),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final _hospitalService = HospitalService();
  final MapController _mapController = MapController();
  final _placeSearchController = TextEditingController();
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);

  LatLng? _currentLocation;
  List<NearbyHospital> _hospitals = [];
  bool _loading = true;
  bool _searchingPlace = false;
  String? _error;
  String? _searchContextLabel;
  NearbyHospital? _selectedHospital;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMapData());
  }

  @override
  void dispose() {
    _placeSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location service is turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please allow location access.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Enable it in device settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final location = LatLng(position.latitude, position.longitude);

      final hospitals = await _hospitalService.fetchNearbyHospitals(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _hospitals = hospitals;
        _selectedHospital = hospitals.isNotEmpty ? hospitals.first : null;
        _searchContextLabel = 'Your current location';
      });
    } catch (error) {
      if (!mounted) return;
      final fallbackHospitals = await _hospitalService.fetchNearbyHospitals(
        latitude: _fallbackCenter.latitude,
        longitude: _fallbackCenter.longitude,
      ).catchError((_) => <NearbyHospital>[]);

      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _currentLocation ??= _fallbackCenter;
        _hospitals = fallbackHospitals;
        _selectedHospital = fallbackHospitals.isNotEmpty ? fallbackHospitals.first : null;
        _searchContextLabel = 'Default area';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _searchByPlace() async {
    final query = _placeSearchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a place to search hospitals nearby.')),
      );
      return;
    }

    setState(() {
      _searchingPlace = true;
      _error = null;
    });

    try {
      final place = await _hospitalService.searchPlace(query);
      final location = LatLng(place.latitude, place.longitude);
      final hospitals = await _hospitalService.fetchNearbyHospitals(
        latitude: place.latitude,
        longitude: place.longitude,
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _hospitals = hospitals;
        _selectedHospital = hospitals.isNotEmpty ? hospitals.first : null;
        _searchContextLabel = place.displayName;
      });
      _mapController.move(location, 13.5);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _searchingPlace = false);
      }
    }
  }

  Future<void> _openHospitalInGoogleMaps(NearbyHospital hospital) async {
    final queryText = hospital.address.trim().isNotEmpty
        ? '${hospital.name}, ${hospital.address}'
        : '${hospital.name} ${hospital.latitude},${hospital.longitude}';

    final googleSearchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': queryText,
    });

    final launched = await launchUrl(
      googleSearchUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      _showSnack(context, 'Could not open Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final current = _currentLocation ?? _fallbackCenter;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nearby Hospitals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _placeSearchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => unawaited(_searchByPlace()),
                decoration: const InputDecoration(
                  hintText: 'Search place (city, area, address)',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searchingPlace ? null : _searchByPlace,
              child: _searchingPlace
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search'),
            ),
          ],
        ),
        if (_searchContextLabel != null) ...[
          const SizedBox(height: 8),
          Text('Showing hospitals near: $_searchContextLabel'),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: Geolocator.openLocationSettings,
                        child: const Text('Open Location Settings'),
                      ),
                      OutlinedButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Open App Settings'),
                      ),
                      FilledButton(
                        onPressed: _loadMapData,
                        child: const Text('Retry Permission'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: current, initialZoom: 13.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.blood.connect',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: current,
                      width: 42,
                      height: 42,
                      child: const Icon(Icons.place, color: Colors.blue, size: 30),
                    ),
                    ..._hospitals.map(
                      (hospital) => Marker(
                        point: LatLng(hospital.latitude, hospital.longitude),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () {
                            final point = LatLng(hospital.latitude, hospital.longitude);
                            _mapController.move(point, 15);
                            setState(() => _selectedHospital = hospital);
                            unawaited(_openHospitalInGoogleMaps(hospital));
                          },
                          child: Icon(
                            Icons.local_hospital,
                            color: _selectedHospital == hospital ? Colors.blue : AppTheme.primary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Nearest Hospitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        if (_hospitals.isEmpty)
          const Text('No nearby hospital found in map data.')
        else
          ..._hospitals.take(8).map(
                (hospital) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () {
                      final point = LatLng(hospital.latitude, hospital.longitude);
                      _mapController.move(point, 15);
                      setState(() => _selectedHospital = hospital);
                      unawaited(_openHospitalInGoogleMaps(hospital));
                    },
                    leading: const Icon(Icons.place_outlined, color: AppTheme.primary),
                    title: Text(hospital.name),
                    subtitle: Text(hospital.address.isEmpty ? 'Address not available' : hospital.address),
                    trailing: const Icon(Icons.navigation_outlined),
                  ),
                ),
              ),
      ],
    );
  }
}

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _backend = SupabaseBackendService.instance;

  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _mobileController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _unitsController = TextEditingController();
  String _group = 'A+';
  bool _loading = false;

  @override
  void dispose() {
    _patientController.dispose();
    _mobileController.dispose();
    _hospitalController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _backend.createBloodRequest(
        patientName: _patientController.text.trim(),
        bloodGroup: _group,
        units: int.parse(_unitsController.text),
        hospital: _hospitalController.text.trim(),
        requesterPhone: _mobileController.text.trim(),
      );

      await LocalNotificationService.instance.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Request submitted',
        body: 'Your $_group request has been shared with nearby donors.',
      );

      if (!mounted) return;
      _showSnack(context, 'Request submitted successfully.');
      _patientController.clear();
      _mobileController.clear();
      _hospitalController.clear();
      _unitsController.clear();
      setState(() => _group = 'A+');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Blood', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Submit details to notify matching donors.', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientController,
              decoration: const InputDecoration(
                hintText: 'Patient name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Enter patient name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: 'Requester mobile number',
                prefixIcon: Icon(Icons.call_outlined),
              ),
              validator: (value) =>
                  _isValidPhoneNumber(value ?? '') ? null : 'Enter a valid 10-digit mobile number',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _group,
              items: bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _group = value);
              },
              decoration: const InputDecoration(
                hintText: 'Blood group needed',
                prefixIcon: Icon(Icons.bloodtype_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Units required',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              validator: (value) {
                final units = int.tryParse(value ?? '');
                if (units == null || units < 1) return 'Enter valid units';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                hintText: 'Hospital / location',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Enter hospital/location' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _loading ? null : _submitRequest,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _backend = SupabaseBackendService.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _ageController = TextEditingController();

  String _group = 'A+';
  String _gender = profileGenders.first;
  bool _available = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _backend.fetchMyProfile();
      if (!mounted) return;
      if (profile != null) {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone;
        _areaController.text = profile.area;
        _ageController.text = profile.age?.toString() ?? '';
        _group = profile.bloodGroup;
        _gender = profileGenders.contains(profile.gender) ? profile.gender : profileGenders.first;
        _available = profile.available;
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack(context, 'Please enter your name.');
      return;
    }

    if (!_isValidPhoneNumber(_phoneController.text)) {
      _showSnack(context, 'Please enter a valid 10-digit mobile number.');
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1) {
      _showSnack(context, 'Please enter a valid age.');
      return;
    }

    if (_gender.trim().isEmpty) {
      _showSnack(context, 'Please select gender.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _backend.updateMyProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodGroup: _group,
        area: _areaController.text.trim(),
        age: age,
        gender: _gender,
        available: _available,
      );
      if (!mounted) return;
      _showSnack(context, 'Profile updated.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0x1AE53935),
                  child: BloodDropLogo(size: 42),
                ),
                const SizedBox(height: 12),
                Text(_nameController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$_group Donor', style: const TextStyle(color: AppTheme.primary)),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _available,
                  onChanged: (value) => setState(() => _available = value),
                  activeThumbColor: AppTheme.primary,
                  title: const Text('Available for donation'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            hintText: 'Phone',
            prefixIcon: Icon(Icons.call_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Age',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(
            hintText: 'Gender',
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          items: profileGenders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _gender = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _areaController,
          decoration: const InputDecoration(
            hintText: 'Area / location',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _group,
          decoration: const InputDecoration(
            hintText: 'Blood Group',
            prefixIcon: Icon(Icons.bloodtype_outlined),
          ),
          items: bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _group = value);
          },
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _saving ? null : _saveProfile,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<int> _expandedNotificationIds = <int>{};

  bool _isRequesterSelfNotification(AppNotification item) {
    return item.title.trim().toLowerCase() == 'request submitted';
  }

  bool _isExpiredRequestNotification(AppNotification item) {
    final isRequestNotification = item.type == 'blood_request' || item.title == 'Request submitted';
    if (!isRequestNotification) return false;
    return DateTime.now().difference(item.createdAt) >= const Duration(hours: 3);
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  Future<String?> _resolveMobileForNotification(AppNotification item) async {
    final details = _parseNotificationDetails(item.subtitle);

    final parsedMobile = _onlyDigits(details['mobile'] ?? '');
    if (parsedMobile.length >= 10) {
      return parsedMobile;
    }

    final inlineMatch = RegExp(r'(?:\+?\d[\d\s\-]{8,}\d)').firstMatch(item.subtitle);
    final inlineMobile = _onlyDigits(inlineMatch?.group(0) ?? '');
    if (inlineMobile.length >= 10) {
      return inlineMobile;
    }

    final backend = SupabaseBackendService.instance;

    if (item.title == 'Request submitted') {
      final profile = await backend.fetchMyProfile();
      final ownMobile = _onlyDigits(profile?.phone ?? '');
      if (ownMobile.length >= 10) {
        return ownMobile;
      }
    }

    final requesterName = (details['requester'] ?? '').trim().toLowerCase();
    final location = (details['location'] ?? '').trim().toLowerCase();
    if (requesterName.isNotEmpty && requesterName != '-') {
      final donors = await backend.fetchDonors();
      for (final donor in donors) {
        final nameMatches = donor.fullName.trim().toLowerCase() == requesterName;
        final areaMatches = location.isEmpty || location == '-' || donor.area.toLowerCase().contains(location);
        if (nameMatches && areaMatches) {
          final donorMobile = _onlyDigits(donor.phone);
          if (donorMobile.length >= 10) {
            return donorMobile;
          }
        }
      }
    }

    return null;
  }

  Map<String, String> _parseNotificationDetails(String subtitle) {
    final details = <String, String>{};
    final parts = subtitle.split('|').map((part) => part.trim()).where((part) => part.isNotEmpty);
    for (final part in parts) {
      final index = part.indexOf(':');
      if (index <= 0) continue;
      final key = part.substring(0, index).trim().toLowerCase();
      final value = part.substring(index + 1).trim();
      if (value.isNotEmpty) {
        details[key] = value;
      }
    }

    String? firstMatch(RegExp pattern) {
      final match = pattern.firstMatch(subtitle);
      final value = match?.group(1)?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final legacyRequester = firstMatch(RegExp(r'^(.+?)\s+needs\s+', caseSensitive: false));
    final legacyLocation = firstMatch(RegExp(r'\sat\s(.+?)(?:\.|\||$)', caseSensitive: false));
    final legacyMobile = firstMatch(RegExp(r'contact\s*:?\s*([0-9+\-\s]{6,})', caseSensitive: false));

    final patient = details['patient'] ?? details['patient name'];
    final location = details['location'] ?? details['hospital'] ?? legacyLocation;
    final mobile = details['callno'] ??
      details['mobile'] ??
      details['mobile no'] ??
      details['phone'] ??
      details['contact'] ??
      legacyMobile;
    final requester = details['requester'] ?? details['requester name'] ?? legacyRequester;
    final group = details['group'] ?? details['blood group'] ?? details['blood'];
    final units = details['units'];
    final requestTag = details['requestid'] ?? details['request id'];

    return {
      'patient': patient ?? '-',
      'location': location ?? '-',
      'mobile': mobile ?? '-',
      'requester': requester ?? '-',
      'group': group ?? '-',
      'units': units ?? '-',
      'requestTag': requestTag ?? '',
    };
  }

  Future<void> _callRequesterFromNotification(AppNotification item) async {
    final mobile = await _resolveMobileForNotification(item);
    if (mobile == null) {
      if (!mounted) return;
      _showSnack(context, 'Mobile number not available in this notification.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: mobile);
    final launched = await launchUrl(uri);
    if (!mounted) return;
    if (!launched) {
      _showSnack(context, 'Could not open phone dialer.');
    }
  }

  Widget _detailLine({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value.isEmpty ? '-' : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = SupabaseBackendService.instance;
    final userId = backend.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AppNotification>>(
        stream: backend.notificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = (snapshot.data ?? [])
              .where((item) => !_isRequesterSelfNotification(item))
              .where((item) => !_isExpiredRequestNotification(item))
              .toList();
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              final details = _parseNotificationDetails(item.subtitle);
              final isExpanded = _expandedNotificationIds.contains(item.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                  leading: const Icon(Icons.notifications, color: AppTheme.primary),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  collapsedShape:
                      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _relativeTime(item.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Call requester',
                        icon: const Icon(Icons.call, color: AppTheme.primary),
                        onPressed: () => unawaited(_callRequesterFromNotification(item)),
                      ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedNotificationIds.add(item.id);
                      } else {
                        _expandedNotificationIds.remove(item.id);
                      }
                    });
                  },
                  children: [
                    _detailLine(icon: Icons.person_outline, label: 'Requester', value: details['requester'] ?? '-'),
                    _detailLine(icon: Icons.personal_injury_outlined, label: 'Patient', value: details['patient'] ?? '-'),
                    _detailLine(icon: Icons.place_outlined, label: 'Location', value: details['location'] ?? '-'),
                    _detailLine(icon: Icons.bloodtype_outlined, label: 'Blood Group', value: details['group'] ?? '-'),
                    _detailLine(icon: Icons.monitor_weight_outlined, label: 'Units', value: details['units'] ?? '-'),
                    _detailLine(icon: Icons.call_outlined, label: 'Mobile', value: details['mobile'] ?? '-'),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => unawaited(_callRequesterFromNotification(item)),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Call'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0x1AE53935),
                    child: BloodDropLogo(size: 42),
                  ),
                  const SizedBox(height: 12),
                  const Text('Blood Plus+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'A community blood donation app to connect donors and patients faster in emergencies.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('What you can do', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.people_alt_outlined, color: AppTheme.primary),
              title: Text('Find donors'),
              subtitle: Text('Search donor list by name, area, and blood group.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.map_outlined, color: AppTheme.primary),
              title: Text('Search hospitals by place'),
              subtitle: Text('Find nearby hospitals around your searched location.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.bloodtype_outlined, color: AppTheme.primary),
              title: Text('Send urgent requests'),
              subtitle: Text('Notify matching available donors quickly.'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for helping save lives through blood donation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class DonateBloodGuidelinesPage extends StatelessWidget {
  const DonateBloodGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guideline For Blood Donation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chapter 1', style: TextStyle(color: Colors.orange, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('General Guidelines For Blood Donation', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: const [
                  _GuideTimelineItem(text: 'Be in good general health and feeling well.', color: Color(0xFF4DB6AC)),
                  _GuideTimelineItem(
                    text: 'Be at least 17 years old in most states (16 years old with parental consent in some states).',
                  ),
                  _GuideTimelineItem(
                    text: 'Weigh at least 110 pounds. Additional weight requirements apply for donors 18 years old and younger and all high school donors.',
                  ),
                  _GuideTimelineItem(text: 'Have not donated blood in the last 56 days.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accent.withValues(alpha: 0.7), Colors.purple.shade100.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Text('How To Get Ready', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(
                  'Donors must have proof of age to ensure they meet the minimum age requirements and present a primary form of ID or two secondary forms of ID.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _GuideStepCard(
                  step: 'Step 1',
                  title: 'Drink Extra Liquids',
                  description: 'Drink an extra 16 oz. of water before your appointment.',
                  icon: Icons.local_drink_outlined,
                ),
                SizedBox(width: 10),
                _GuideStepCard(
                  step: 'Step 2',
                  title: 'Select Appointment',
                  description: 'Choose a nearby center and schedule your donation time.',
                  icon: Icons.calendar_month_outlined,
                ),
                SizedBox(width: 10),
                _GuideStepCard(
                  step: 'Step 3',
                  title: 'Take Rest',
                  description: 'Sleep well before donation and avoid heavy stress.',
                  icon: Icons.nightlight_round,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTimelineItem extends StatelessWidget {
  const _GuideTimelineItem({required this.text, this.color = const Color(0xFF78909C)});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 1, height: 54, color: color.withValues(alpha: 0.35)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 2),
            child: Text(text),
          ),
        ),
      ],
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String step;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.lightBlue.shade300,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(step, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 8),
              Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSync extends StatefulWidget {
  const NotificationSync({super.key, required this.userId, required this.child});

  final String? userId;
  final Widget child;

  @override
  State<NotificationSync> createState() => _NotificationSyncState();
}

class _NotificationSyncState extends State<NotificationSync> {
  StreamSubscription<List<AppNotification>>? _subscription;
  Timer? _cleanupTimer;
  final Set<int> _seenIds = {};
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant NotificationSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _subscription?.cancel();
      _cleanupTimer?.cancel();
      _seenIds.clear();
      _seeded = false;
      _start();
    }
  }

  void _start() {
    final userId = widget.userId;
    if (userId == null) return;

    unawaited(_runExpiryCleanup());
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_runExpiryCleanup());
    });

    _subscription = SupabaseBackendService.instance.notificationsStream(userId).listen((items) {
      if (!_seeded) {
        for (final item in items) {
          _seenIds.add(item.id);
        }
        _seeded = true;
        return;
      }

      for (final item in items) {
        if (_seenIds.add(item.id)) {
          unawaited(
            LocalNotificationService.instance.show(
              id: item.id,
              title: item.title,
              body: item.subtitle,
            ),
          );
        }
      }
    });
  }

  Future<void> _runExpiryCleanup() async {
    try {
      await SupabaseBackendService.instance.cleanupExpiredRequestNotifications();
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class BloodDropLogo extends StatelessWidget {
  const BloodDropLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class NavItem {
  const NavItem({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const List<String> profileGenders = ['Male', 'Female', 'Other'];

const List<NavItem> _navItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  NavItem(label: 'Donors', icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt),
  NavItem(label: 'Map', icon: Icons.map_outlined, selectedIcon: Icons.map),
  NavItem(
    label: 'Request',
    icon: Icons.volunteer_activism_outlined,
    selectedIcon: Icons.volunteer_activism,
  ),
  NavItem(label: 'Profile', icon: Icons.person_outline, selectedIcon: Icons.person),
];

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

bool _isValidPhoneNumber(String value) {
  final trimmed = value.trim();
  return RegExp(r'^\d{10}$').hasMatch(trimmed);
}
