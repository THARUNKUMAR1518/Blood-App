import 'package:flutter/material.dart';

void main() {
  runApp(const BloodApp());
}

class BloodApp extends StatelessWidget {
  const BloodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Connect',
      theme: AppTheme.theme,
      home: const LoginScreen(),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'test@bloodapp.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                  'Sign in to continue helping save lives.',
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
                    onPressed: _login,
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _bloodGroup = 'A+';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  items: bloodGroups
                      .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                      .toList(),
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
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Password must be 6+ characters'
                      : null,
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
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AppShell()),
                        (route) => false,
                      );
                    },
                    child: const Text('Create account'),
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
  int _index = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _goToIndex),
    const DonorListScreen(),
    const MapScreen(),
    const RequestBloodScreen(),
    const ProfileScreen(),
  ];

  void _goToIndex(int index) {
    setState(() => _index = index);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_index].label),
      ),
      drawer: MainMenuDrawer(
        onOpenTab: _goToIndex,
        onOpenPage: (page) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
        },
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
      body: _screens[_index],
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0x1AE53935),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: BloodDropLogo(size: 34),
                  ),
                  SizedBox(height: 10),
                  Text('Rahul Sharma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('A+ Donor', style: TextStyle(color: AppTheme.primary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _menuTile(context, Icons.home_outlined, 'Home', () => onOpenTab(0)),
                  _menuTile(context, Icons.people_alt_outlined, 'Donors', () => onOpenTab(1)),
                  _menuTile(context, Icons.map_outlined, 'Map', () => onOpenTab(2)),
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
                    Icons.history,
                    'Donation History',
                    () => onOpenPage(const DonationHistoryPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.event_available_outlined,
                    'Campaigns',
                    () => onOpenPage(const CampaignsPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () => onOpenPage(const SettingsPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    () => onOpenPage(const HelpPage()),
                  ),
                  _menuTile(
                    context,
                    Icons.info_outline,
                    'About',
                    () => onOpenPage(const AboutPage()),
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
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

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
              Text('Urgent Need', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text(
                '2 units of O- required near City Hospital',
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
              onTap: () => onNavigate(1),
            ),
            ActionCard(
              title: 'Map',
              icon: Icons.map_outlined,
              onTap: () => onNavigate(2),
            ),
            ActionCard(
              title: 'Request Blood',
              icon: Icons.bloodtype_outlined,
              onTap: () => onNavigate(3),
            ),
            ActionCard(
              title: 'Profile',
              icon: Icons.person_outline,
              onTap: () => onNavigate(4),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Nearby Donors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        ...donors.take(3).map((donor) => DonorCard(donor: donor)),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.title, required this.icon, required this.onTap});

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
  String _query = '';
  String _selectedGroup = 'All';

  List<Donor> get _filtered {
    return donors.where((donor) {
      final search = _query.toLowerCase();
      final matchName = donor.name.toLowerCase().contains(search);
      final matchArea = donor.area.toLowerCase().contains(search);
      final groupMatch = _selectedGroup == 'All' || donor.group == _selectedGroup;
      return (matchName || matchArea) && groupMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ['All', ...{...donors.map((item) => item.group)}];

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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtered.length,
            itemBuilder: (_, index) {
              final donor = _filtered[index];
              return DonorCard(
                donor: donor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DonorDetailPage(donor: donor)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DonorCard extends StatelessWidget {
  const DonorCard({super.key, required this.donor, this.onTap});

  final Donor donor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0x1AE53935),
          child: Text(
            donor.group,
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${donor.area} • ${donor.distanceKm} km away'),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: AppTheme.primary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling ${donor.name}...')),
            );
          },
        ),
      ),
    );
  }
}

class DonorDetailPage extends StatelessWidget {
  const DonorDetailPage({super.key, required this.donor});

  final Donor donor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0x1AE53935),
                    child: Text(
                      donor.group,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(donor.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(donor.area),
                  Text('${donor.distanceKm} km away'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {},
            icon: const Icon(Icons.call),
            label: const Text('Call Donor'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message'),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Donor Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Find nearby donors based on your location.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 14),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: const [
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.map_outlined, size: 100, color: Color(0xFFBFC5D2)),
                ),
              ),
              Positioned(
                left: 60,
                top: 90,
                child: Icon(Icons.location_on, color: AppTheme.primary, size: 28),
              ),
              Positioned(
                right: 80,
                top: 120,
                child: Icon(Icons.location_on, color: AppTheme.primary, size: 28),
              ),
              Positioned(
                left: 120,
                bottom: 70,
                child: Icon(Icons.location_on, color: AppTheme.primary, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Nearest Spots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        ...donors.take(4).map(
          (donor) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.place_outlined, color: AppTheme.primary),
              title: Text('${donor.group} donor - ${donor.name}'),
              subtitle: Text('${donor.area} • ${donor.distanceKm} km'),
              trailing: const Icon(Icons.chevron_right),
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
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _unitsController = TextEditingController();
  String _group = 'A+';

  @override
  void dispose() {
    _patientController.dispose();
    _hospitalController.dispose();
    _unitsController.dispose();
    super.dispose();
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
            Text('Fill details to notify nearby donors.', style: TextStyle(color: Colors.grey.shade700)),
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
              items: bloodGroups
                  .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                  .toList(),
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
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request submitted for $_group blood group')),
                  );
                  _formKey.currentState!.reset();
                  _patientController.clear();
                  _hospitalController.clear();
                  _unitsController.clear();
                  setState(() => _group = 'A+');
                },
                child: const Text('Submit Request'),
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
  final _nameController = TextEditingController(text: 'Rahul Sharma');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  String _group = 'A+';
  bool _available = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          decoration: const InputDecoration(
            hintText: 'Phone',
            prefixIcon: Icon(Icons.call_outlined),
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
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated')),
            );
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
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

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appNotifications.length,
        itemBuilder: (_, index) {
          final item = appNotifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(item.icon, color: AppTheme.primary),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: Text(item.time, style: const TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}

class DonationHistoryPage extends StatelessWidget {
  const DonationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: donationHistory.length,
        itemBuilder: (_, index) {
          final item = donationHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const BloodDropLogo(size: 26),
              title: Text(item.location),
              subtitle: Text(item.date),
              trailing: Text(item.group, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...campaigns.map(
            (campaign) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(campaign.details),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Join Campaign'),
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
            title: const Text('Push Notifications'),
            activeThumbColor: AppTheme.primary,
          ),
          SwitchListTile(
            value: _emailAlerts,
            onChanged: (value) => setState(() => _emailAlerts = value),
            title: const Text('Email Alerts'),
            activeThumbColor: AppTheme.primary,
          ),
          SwitchListTile(
            value: _darkMode,
            onChanged: (value) => setState(() => _darkMode = value),
            title: const Text('Dark Mode'),
            activeThumbColor: AppTheme.primary,
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HelpTile(question: 'How to request blood?', answer: 'Go to Request Blood tab and submit the form.'),
          HelpTile(question: 'How to find donors?', answer: 'Use Donors tab and filter by blood group.'),
          HelpTile(question: 'How to update profile?', answer: 'Open Profile tab and tap Save Changes.'),
        ],
      ),
    );
  }
}

class HelpTile extends StatelessWidget {
  const HelpTile({super.key, required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(question),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: BloodDropLogo(size: 86)),
            SizedBox(height: 16),
            Text('Blood Connect', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 14),
            Text('Blood Connect helps people quickly find donors and raise urgent blood requests.'),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  const NavItem({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class Donor {
  const Donor({required this.name, required this.group, required this.area, required this.distanceKm});

  final String name;
  final String group;
  final String area;
  final double distanceKm;
}

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
}

class DonationItem {
  const DonationItem({required this.location, required this.date, required this.group});

  final String location;
  final String date;
  final String group;
}

class Campaign {
  const Campaign({required this.title, required this.details});

  final String title;
  final String details;
}

const List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

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

const List<Donor> donors = [
  Donor(name: 'Aman Gupta', group: 'A+', area: 'MG Road', distanceKm: 2.1),
  Donor(name: 'Priya Nair', group: 'O-', area: 'City Center', distanceKm: 3.8),
  Donor(name: 'Sohail Khan', group: 'B+', area: 'Lake View', distanceKm: 1.5),
  Donor(name: 'Neha Das', group: 'AB+', area: 'North Zone', distanceKm: 4.2),
  Donor(name: 'Vikram Roy', group: 'O+', area: 'Green Park', distanceKm: 5.0),
  Donor(name: 'Isha Mehta', group: 'A-', area: 'West Avenue', distanceKm: 2.9),
];

const List<NotificationItem> appNotifications = [
  NotificationItem(
    title: 'Urgent O- request',
    subtitle: 'City Hospital needs 2 units now',
    time: '5m ago',
    icon: Icons.warning_amber_rounded,
  ),
  NotificationItem(
    title: 'Donor accepted request',
    subtitle: 'Aman Gupta is on the way',
    time: '25m ago',
    icon: Icons.check_circle_outline,
  ),
  NotificationItem(
    title: 'Campaign reminder',
    subtitle: 'Community camp starts tomorrow',
    time: '1d ago',
    icon: Icons.event_note,
  ),
];

const List<DonationItem> donationHistory = [
  DonationItem(location: 'City Blood Bank', date: '12 Feb 2026', group: 'A+'),
  DonationItem(location: 'Green Care Hospital', date: '04 Nov 2025', group: 'A+'),
  DonationItem(location: 'Community Camp', date: '20 Jul 2025', group: 'A+'),
];

const List<Campaign> campaigns = [
  Campaign(
    title: 'Save Lives Weekend Drive',
    details: 'Join us this weekend at City Hall to donate and support emergency units.',
  ),
  Campaign(
    title: 'University Blood Camp',
    details: 'Volunteer and donate at the campus central block from 10 AM to 4 PM.',
  ),
];
