import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
import 'dart:io';
import 'package:dio_web_adapter/dio_web_adapter.dart';


class ApiService {
  final String _baseUrl = 'https://mysahayog.com';
  late Dio _dio;
  late CookieJar _cookieJar;

  ApiService();

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    if (kIsWeb) {
      _dio.httpClientAdapter = BrowserHttpClientAdapter(
        withCredentials: true,
      );
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = '${appDocDir.path}/.cookies/';
      _cookieJar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage(cookiePath),
      );
      _dio.interceptors.add(CookieManager(_cookieJar));
    }

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<bool> isLoggedIn() async {
    if (kIsWeb) {
      // On web, we cannot reliably check for a session without a universally whitelisted endpoint.
      // We will assume the user is logged out and let them log in.
      // The session will be maintained by the browser's cookies for subsequent requests.
      return Future.value(false);
    } else {
      final cookies = await _cookieJar.loadForRequest(Uri.parse(_baseUrl));
      return cookies.any((c) => c.name == 'sid');
    }
  }

  Future<void> login(String usr, String pwd) async {
    try {
      await _dio.post(
        '/api/method/login',
        data: {'usr': usr, 'pwd': pwd},
      );
    } on DioException catch (e) {
      log('Login Error: $e');
      throw Exception('Failed to connect to the server: ${e.message}');
    }
  }

  Future<void> logout() async {
    await _cookieJar.deleteAll();
    try {
      await _dio.post('/api/method/logout');
    } on DioException catch (e) {
      log('Logout error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String empId) async {
    try {
      final response = await _dio.post(
        '/api/method/sahayog_ticket.sahayog_ticket.doctype.sahayog_ticket.sahayog_ticket.get_user_details',
        data: {'username': empId},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data.containsKey('message')) {
          return data['message'];
        }
        return data;
      } else {
        throw Exception(
            'Failed to get user details. Status code: ${response.statusCode}, Body: ${response.data}');
      }
    } on DioException catch (e) {
      log('getUserDetails Error: $e');
      throw Exception('Failed to connect to the server: ${e.message}');
    }
  }

  Future<void> resetUserPassword(String email, String newPassword) async {
    try {
      await _dio.post(
        '/api/method/sahayog_ticket.sahayog_ticket.doctype.sahayog_ticket.sahayog_ticket.reset_user_password',
        data: {
          'email': email,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      log('resetUserPassword Error: $e');
      throw Exception('Failed to connect to the server: ${e.message}');
    }
  }
}