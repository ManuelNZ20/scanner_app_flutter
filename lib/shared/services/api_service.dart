import 'dart:convert';

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

  static Future<List<Map<String, dynamic>>> scanQRCode(String code) async {
    try {
      final response = await _dio.get(
        '/auth/type-profile',
        // '/auth/role-profile',
        options: Options(receiveTimeout: Duration(seconds: 5)),
      );
      if (response.statusCode == 200) {
        if (response.data is List) {
          // Convertir cada item a Map<String, dynamic>
          final List<dynamic> responseList = response.data;
          return responseList.map<Map<String, dynamic>>((item) {
            return item is Map<String, dynamic>
                ? item
                : {'data': item.toString()};
          }).toList();
        } else {
          throw Exception(
            'Formato de respuesta no válido ${response.data} ${response.statusCode}',
          );
        }
      } else {
        throw Exception('Error en la API: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error del servidor: ${e.response!.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
    // return {'success': true, 'qrData': code};
  }
}
