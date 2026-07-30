import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._client);

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<AuthResponse> login(String email, String password) async {
    // Try local auth first
    final usersJson = await _storage.read(key: 'local_users');
    if (usersJson != null) {
      final users = jsonDecode(usersJson) as Map<String, dynamic>;
      final userData = users[email];
      if (userData != null && userData['password'] == password) {
        final user = UserModel.fromJson(userData as Map<String, dynamic>);
        final token = 'local_token_${user.id}';
        await _client.setTokens(token, token);
        return AuthResponse(user: user, accessToken: token, refreshToken: token);
      }
    }

    // Fallback to API
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = AuthResponse.fromJson(response.data['data']);
      await _client.setTokens(data.accessToken, data.refreshToken);
      return data;
    } catch (_) {
      throw Exception('Invalid credentials or server unavailable');
    }
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      fitnessLevel: 'BEGINNER',
    );

    // Store locally
    final usersJson = await _storage.read(key: 'local_users');
    final users = usersJson != null
        ? jsonDecode(usersJson) as Map<String, dynamic>
        : <String, dynamic>{};

    if (users.containsKey(email)) {
      throw Exception('Email already registered');
    }

    final userMap = {
      ...user.toJson(),
      'password': password,
    };
    users[email] = userMap;
    await _storage.write(key: 'local_users', value: jsonEncode(users));

    final token = 'local_token_${user.id}';
    await _client.setTokens(token, token);
    return AuthResponse(user: user, accessToken: token, refreshToken: token);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {}
    await _client.clearTokens();
  }

  Future<UserModel> getProfile() async {
    // Check local storage first
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.startsWith('local_token_')) {
      final usersJson = await _storage.read(key: 'local_users');
      if (usersJson != null) {
        final users = jsonDecode(usersJson) as Map<String, dynamic>;
        final email = await _storage.read(key: 'local_email');
        if (email != null && users.containsKey(email)) {
          return UserModel.fromJson(users[email] as Map<String, dynamic>);
        }
      }
    }

    // Fallback to API
    try {
      final response = await _client.get(ApiConstants.profile);
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      throw Exception('Not authenticated');
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    // Update locally
    final usersJson = await _storage.read(key: 'local_users');
    if (usersJson != null) {
      final users = jsonDecode(usersJson) as Map<String, dynamic>;
      final email = await _storage.read(key: 'local_email');
      if (email != null && users.containsKey(email)) {
        users[email].addAll(data);
        await _storage.write(key: 'local_users', value: jsonEncode(users));
        return UserModel.fromJson(users[email] as Map<String, dynamic>);
      }
    }

    // Fallback to API
    try {
      final response = await _client.put(ApiConstants.profile, data: data);
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      throw Exception('Failed to update profile');
    }
  }

  // Save current email for local lookup
  Future<void> saveCurrentEmail(String email) async {
    await _storage.write(key: 'local_email', value: email);
  }
}
