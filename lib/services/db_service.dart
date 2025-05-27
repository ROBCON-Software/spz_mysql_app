import 'package:dart_mysql/dart_mysql.dart';
import '../globals.dart' as globals;
import '../models/car.dart'; // Assuming you might create a User/PIN model later if needed

class DBService {
  Future<MySqlConnection> _getConnection() async {
    return await MySqlConnection.connect(ConnectionSettings(
      host: globals.serverIp,
      port: globals.serverPort,
      user: globals.loginName,
      password: globals.loginPassword,
      db: globals.databaseName,
    ));
  }

  Future<Car?> getCarByLicensePlate(String licensePlate) async {
    print('Hľadám auto so ŠPZ: $licensePlate');
    MySqlConnection? conn; // Declare conn here to access in finally
    try {
      conn = await _getConnection();
      var results = await conn.query(
        'SELECT car_lic_plate, car_details, car_color, car_owner_name, car_owner_surname, car_owner_phone FROM spz_db WHERE car_lic_plate = ?',
        [licensePlate],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        // Ensure proper null handling or default values if fields can be null in DB
        return Car(
          carLicPlate: row[0]?.toString() ?? '', // Example: handle potential nulls
          carDetails: row[1]?.toString() ?? '',
          carColor: row[2]?.toString() ?? '',
          ownerName: row[3]?.toString() ?? '',
          ownerSurname: row[4]?.toString() ?? '',
          ownerPhone: row[5]?.toString() ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error in getCarByLicensePlate: $e');
      return null; // Or throw e; depending on how you want to handle errors
    } finally {
      await conn?.close(); // Close connection in finally block
    }
  }

  // --- NEW METHOD TO GET ALL VALID PINS ---
  Future<List<String>> getAllValidPins() async {
    print('Fetching all valid PINs...');
    MySqlConnection? conn; // Declare conn here to access in finally
    List<String> pins = [];

    try {
      conn = await _getConnection();
      var results = await conn.query(
        'SELECT pin_number FROM spz_db_users', // Query your user table and PIN column
      );

      if (results.isNotEmpty) {
        for (var row in results) {
          // Assuming pin_number is the first (and only) column selected.
          // The dart_mysql package returns values that might need explicit casting.
          // row[0] gives the value of the first column in the current row.
          if (row[0] != null) {
            pins.add(row[0].toString()); // Ensure it's treated as a String
          }
        }
        print('Found ${pins.length} PINs: $pins'); // For debugging
      } else {
        print('No PINs found in spz_db_users table.');
      }
    } catch (e) {
      print('Error in getAllValidPins: $e');
      // Depending on your error handling strategy, you might want to:
      // - return an empty list (as it currently does implicitly if an error occurs before pins are populated)
      // - rethrow the error: throw e;
      // - return a specific error indicator
    } finally {
      await conn?.close(); // Ensure connection is always closed
    }
    return pins;
  }
// --- END OF NEW METHOD ---

// Pridaj ďalšie CRUD metódy podľa potreby (insert, update, delete)
// napr. Future<void> addUser(String username, String hashedPin) async { ... }
//       Future<void> updateCarDetails(Car car) async { ... }
}