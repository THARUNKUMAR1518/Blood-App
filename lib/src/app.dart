import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_models.dart';
import 'services/hospital_service.dart';
import 'services/local_notification_service.dart';
import 'services/supabase_backend_service.dart';

class BloodApp extends StatelessWidget {
  const BloodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Connect',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFFE53935);
  static const primaryDark = Color(0xFFB71C1C);
  static const accent = Color(0xFFFF8A80);
  static const background = Color(0xFFF8F9FB);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.3),
        ),
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

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack(context, 'Enter your email first.');
      return;
    }

    try {
      await _backend.resendConfirmationEmail(email);
      if (!mounted) return;
      _showSnack(context, 'Confirmation email sent. Check inbox/spam.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final currentContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a password reset link.'),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  _showSnack(currentContext, 'Enter a valid email');
                  return;
                }

                try {
                  await _backend.resetPassword(email);
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(dialogContext).pop();
                  // ignore: use_build_context_synchronously
                  _showSnack(currentContext, 'Password reset link sent to your email.');
                } catch (error) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  _showSnack(currentContext, error.toString());
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('Forgot password?'),
                          ),
                          TextButton(
                            onPressed: _resendConfirmation,
                            child: const Text('Resend email'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account? '),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
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
  String _bloodGroup = 'A+';
  bool _loading = false;

  Future<void> _resendConfirmationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack(context, 'Enter your email first.');
      return;
    }

    try {
      await SupabaseBackendService.instance.resendConfirmationEmail(email);
      if (!mounted) return;
      _showSnack(context, 'Confirmation email sent. Check inbox/spam.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

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
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                  validator: (value) => (value == null || value.length < 8) ? 'Enter valid phone' : null,
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
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be 6+ characters' : null,
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resendConfirmationEmail,
                    child: const Text('Resend confirmation email'),
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
  int _index = 0;
  bool _profilePromptShown = false;

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
      setState(() => _index = 4);
    });
  }

  void _goToIndex(int index) {
    setState(() => _index = index);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _backend.currentUser?.id;

    return NotificationSync(
      userId: userId,
      child: Scaffold(
        appBar: AppBar(title: Text(_navItems[_index].label)),
        drawer: MainMenuDrawer(
          onOpenTab: _goToIndex,
          onOpenPage: (page) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
          },
          onLogout: () async {
            await _backend.signOut();
          },
        ),
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenTab: (index) => setState(() => _index = index)),
            const DonorListScreen(),
            const HospitalMapScreen(),
            const RequestBloodScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
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
                        profile?.fullName ?? 'Blood Connect User',
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
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
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
      onTap: onTap,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Urgent Blood Support', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text(
                'Use Request tab to notify matching donors instantly.',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            ActionCard(
              title: 'Find Donor',
              icon: Icons.search,
              onTap: () => onOpenTab(1),
            ),
            ActionCard(
              title: 'Hospital Map',
              icon: Icons.map_outlined,
              onTap: () => onOpenTab(2),
            ),
            ActionCard(
              title: 'Request Blood',
              icon: Icons.bloodtype_outlined,
              onTap: () => onOpenTab(3),
            ),
            ActionCard(
              title: 'My Profile',
              icon: Icons.person_outline,
              onTap: () => onOpenTab(4),
            ),
          ],
        ),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
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
  String _query = '';
  String _selectedGroup = 'All';

  @override
  void initState() {
    super.initState();
    unawaited(_loadDonors());
  }

  Future<void> _loadDonors() async {
    setState(() => _loading = true);
    try {
      final donors = await _backend.fetchAvailableDonors();
      if (!mounted) return;
      setState(() => _allDonors = donors);
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DonorProfile> get _filtered {
    return _allDonors.where((donor) {
      final search = _query.toLowerCase();
      final matchName = donor.fullName.toLowerCase().contains(search);
      final matchArea = donor.area.toLowerCase().contains(search);
      final groupMatch = _selectedGroup == 'All' || donor.bloodGroup == _selectedGroup;
      return (matchName || matchArea) && groupMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ['All', ...{..._allDonors.map((item) => item.bloodGroup)}];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search donors by name or area',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) {
              final group = groups[index];
              final selected = _selectedGroup == group;
              return ChoiceChip(
                label: Text(group),
                selected: selected,
                onSelected: (_) => setState(() => _selectedGroup = group),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: groups.length,
          ),
        ),
        const SizedBox(height: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0x1AE53935),
          child: Text(
            donor.bloodGroup,
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(donor.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${donor.area} • ${donor.phone}'),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: AppTheme.primary),
          onPressed: () => _callDonor(context),
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
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);

  LatLng? _currentLocation;
  List<NearbyHospital> _hospitals = [];
  bool _loading = true;
  String? _error;
  NearbyHospital? _selectedHospital;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMapData());
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
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                    ..._hospitals.map(
                      (hospital) => Marker(
                        point: LatLng(hospital.latitude, hospital.longitude),
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.local_hospital,
                          color: _selectedHospital == hospital ? Colors.blue : AppTheme.primary,
                          size: 30,
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
  final _hospitalController = TextEditingController();
  final _unitsController = TextEditingController();
  String _group = 'A+';
  bool _loading = false;

  @override
  void dispose() {
    _patientController.dispose();
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
      );

      await LocalNotificationService.instance.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Request submitted',
        body: 'Your $_group request has been shared with nearby donors.',
      );

      if (!mounted) return;
      _showSnack(context, 'Request submitted successfully.');
      _patientController.clear();
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
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().length < 8) {
      _showSnack(context, 'Please enter valid profile details.');
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

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: AppTheme.primary),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: Text(_relativeTime(item.createdAt), style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          );
        },
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
      _seenIds.clear();
      _seeded = false;
      _start();
    }
  }

  void _start() {
    final userId = widget.userId;
    if (userId == null) return;

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

  @override
  void dispose() {
    _subscription?.cancel();
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
