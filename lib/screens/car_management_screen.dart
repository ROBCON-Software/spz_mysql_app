import 'package:flutter/material.dart';

class CarManagementScreen extends StatefulWidget {
  const CarManagementScreen({super.key});

  @override
  State<CarManagementScreen> createState() => _CarManagementScreenState();
}

class _CarManagementScreenState extends State<CarManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Database Management'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Add New Car'),
            onTap: () {
              // Navigator.push(... to AddCarScreen);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Existing Car'),
            onTap: () {
              // Navigator.push(... to EditCarScreen);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Car'),
            onTap: () {
              // Navigator.push(... to DeleteCarScreen);
            },
          ),
        ],
      ),
    );
  }
}