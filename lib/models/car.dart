class Car {
  final String carLicPlate;
  final String carDetails;
  final String carColor;
  final String ownerName;
  final String ownerSurname;
  final String ownerPhone;

  Car({
    required this.carLicPlate,
    required this.carDetails,
    required this.carColor,
    required this.ownerName,
    required this.ownerSurname,
    required this.ownerPhone,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carLicPlate: json['car_lic_plate'] ?? '',
      carDetails: json['car_details'] ?? '',
      carColor: json['car_color'] ?? '',
      ownerName: json['car_owner_name'] ?? '',
      ownerSurname: json['car_owner_surname'] ?? '',
      ownerPhone: json['car_owner_phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'carLicPlate': carLicPlate,
    'carDetails': carDetails,
    'carColor': carColor,
    'ownerName': ownerName,
    'ownerSurname': ownerSurname,
    'ownerPhone': ownerPhone,
  };
}