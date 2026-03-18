import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';

class SupabaseBackendService {
  SupabaseBackendService._();

  static final SupabaseBackendService instance = SupabaseBackendService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  Future<void> resendConfirmationEmail(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> syncMyProfileFromAuthMetadata() async {
    final user = currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final age = int.tryParse((metadata['age'] ?? '').toString());

    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': (metadata['full_name'] ?? user.email ?? 'New User').toString(),
        'phone': (metadata['phone'] ?? '').toString(),
        'blood_group': (metadata['blood_group'] ?? 'A+').toString(),
        'area': (metadata['area'] ?? '').toString(),
        'age': age,
        'gender': (metadata['gender'] ?? '').toString(),
        'available': true,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        await signOut();
        return;
      }
      rethrow;
    }
  }

  Future<void> ensureProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String bloodGroup,
    String area = '',
    int? age,
    String gender = '',
    bool available = true,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'blood_group': bloodGroup,
      'area': area,
      'age': age,
      'gender': gender,
      'available': available,
    });
  }

  Future<DonorProfile?> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return DonorProfile.fromJson(data);
  }

  Future<List<DonorProfile>> fetchDonors({bool? availableOnly}) async {
    var query = _client.from('profiles').select();
    if (availableOnly == true) {
      query = query.eq('available', true);
    }
    final data = await query.order('full_name');

    return (data as List)
        .map((item) => DonorProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DonorProfile>> fetchAvailableDonors() {
    return fetchDonors(availableOnly: true);
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String phone,
    required String bloodGroup,
    required String area,
    required int age,
    required String gender,
    required bool available,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'phone': phone,
        'blood_group': bloodGroup,
        'area': area,
        'age': age,
        'gender': gender,
        'available': available,
      });
    } on PostgrestException catch (error) {
      if (error.code == '42703' || error.code == '42P01') {
        throw Exception('Database schema is outdated. Please run latest supabase/schema.sql and try again.');
      }
      rethrow;
    }

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName,
          'phone': phone,
          'blood_group': bloodGroup,
          'area': area,
          'age': age,
          'gender': gender,
        },
      ),
    );
  }

  Future<void> createBloodRequest({
    required String patientName,
    required String bloodGroup,
    required int units,
    required String hospital,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Please login again.');
    }

    await _client.from('blood_requests').insert({
      'user_id': user.id,
      'patient_name': patientName,
      'blood_group': bloodGroup,
      'units': units,
      'hospital': hospital,
      'status': 'open',
    });

    final requesterProfile = await fetchMyProfile();
    final requesterName = requesterProfile?.fullName ?? 'Someone';

    final matchingDonors = await _client
        .from('profiles')
        .select('id')
        .eq('available', true)
        .eq('blood_group', bloodGroup)
        .neq('id', user.id);

    if (matchingDonors.isNotEmpty) {
      final notifications = matchingDonors
          .map((item) => {
                'user_id': item['id'],
                'title': 'Urgent $bloodGroup request',
                'subtitle': '$requesterName needs $units unit(s) at $hospital',
                'type': 'blood_request',
              })
          .toList();
      await _client.from('notifications').insert(notifications);
    }

    await _client.from('notifications').insert({
      'user_id': user.id,
      'title': 'Request submitted',
      'subtitle':
          'We notified nearby donors for $bloodGroup at $hospital.',
      'type': 'system',
    });
  }

  Stream<List<AppNotification>> notificationsStream(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((item) => AppNotification.fromJson(item))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }
}
