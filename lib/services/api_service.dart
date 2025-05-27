import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/car.dart';

class ApiService {
  static const String _baseUrl = 'http://195.80.183.109:25001/spz_db';

  Future<Car?> getCarByLicensePlate(String licensePlate) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get_car.php?spz=${Uri.encodeComponent(licensePlate)}'),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return Car.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Car not found');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection failed: ${e.message}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}