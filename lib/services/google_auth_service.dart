import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:blink_app/config/api_config.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/auth_service.dart';

class GoogleAuthService {
  final Logger _logger = Logger();
  final StorageService _storageService;
  final AuthService _authService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add server client ID for Android/iOS
    serverClientId:
        '402547583247-6p1ahq0tj8o6d3opmp69duv5h0p6c8j6.apps.googleusercontent.com',
  );

  GoogleAuthService({
    required StorageService storageService,
    required AuthService authService,
  })  : _storageService = storageService,
        _authService = authService;

  /// Handles the Google Sign-In flow
  Future<Map<String, dynamic>> signInWithGoogle(BuildContext context) async {
    try {
      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled sign-in
        _logger.w('Google sign-in was canceled by the user');
        throw Exception('Sign in canceled by user');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _logger.e('Failed to get ID token from Google');
        throw Exception('Failed to get ID token');
      }

      // Split name into first and last name
      String fullName = googleUser.displayName ?? '';
      List<String> nameParts = fullName.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Call backend API
      final response = await _makeGoogleAuthRequest(
        idToken: idToken,
        email: googleUser.email,
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
      );

      // Handle the response
      if (response['token'] != null) {
        // Store the token
        await _storageService.setToken(response['token']);

        // Store user ID if available
        if (response['userId'] != null) {
          await _storageService.setUserId(response['userId']);
        }

        // Store user data if this is a new user
        if (response['isNewUser'] == true) {
          await _storageService.setEmail(googleUser.email);
          if (firstName.isNotEmpty) {
            await _storageService.setFirstName(firstName);
          }
          if (lastName.isNotEmpty) {
            await _storageService.setLastName(lastName);
          }

          // Add firstName and lastName to the response
          response['firstName'] = firstName;
          response['lastName'] = lastName;
          response['email'] = googleUser.email;
        }
      }

      // Return the response for the caller to handle navigation
      return response;
    } catch (e) {
      _logger.e('Error during Google sign-in:', error: e);
      rethrow;
    }
  }

  /// Makes the request to the backend API for Google authentication
  Future<Map<String, dynamic>> _makeGoogleAuthRequest({
    required String idToken,
    required String email,
    required String fullName,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/google');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'idToken': idToken,
          'email': email,
          'name': fullName,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      _logger.i('Google auth response status code: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        _logger.i(
            'Google auth successful: ${decodedResponse['isNewUser'] ? 'New User' : 'Existing User'}');
        return decodedResponse;
      } else {
        _logger
            .e('Google auth error: ${response.statusCode} - ${response.body}');
        throw Exception('Google authentication failed: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error making Google auth request:', error: e);
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _logger.i('Signed out from Google');
    } catch (e) {
      _logger.e('Error signing out from Google:', error: e);
      rethrow;
    }
  }
}
