import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['ENDPOINT_API'] ?? '',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  static Future<Map<String, dynamic>> sendScannedData(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      final response = await _dio.get(
        '/auth/type-profile',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return {
        'success': true,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data ?? e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> testConnection() async {
    try {
      print('BASE: ${_dio.options.baseUrl}');
      final response = await _dio.get(
        '/auth/role-profile',
        options: Options(receiveTimeout: Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
