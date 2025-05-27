import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../services/api_service.dart';
import '../models/car.dart';
import '../globals.dart' as globals;
import 'car_management_screen.dart';
import 'pin_entry_screen.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int isAdminFlag;
  final String userName;

  const HomeScreen({
    super.key,
    required this.isAdminFlag,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _spzController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);
  final FocusNode _spzFocusNode = FocusNode();

  late bool _isMenuEnabled;
  late bool _canEditRecords;
  final bool _isAppbarExitEnabled = true;

  Car? _car;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _isMenuEnabled = widget.isAdminFlag == 1;
    _canEditRecords = widget.isAdminFlag == 1;

    _spzController.addListener(_onSpzChangeOrFocus);
    _spzFocusNode.addListener(_onSpzChangeOrFocus);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _onSpzChangeOrFocus();
    //   if (mounted && _car == null && _spzController.text.isEmpty) {
    //     FocusScope.of(context).requestFocus(_spzFocusNode);
    //   }
    // });
  }

  void _onSpzChangeOrFocus() {
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToPinEntry() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PinEntryScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToCarManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CarManagementScreen(),
      ),
    );
  }

  Future<void> _searchCar() async {
    final spz = _spzController.text.trim();
    _spzFocusNode.unfocus();

    if (spz.isEmpty) {
      if (mounted) {
        setState(() {
          _message = 'SPZ cannot be blank';
          _car = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _message = 'Searching...';
        _car = null;
      });
    }
    try {
      final car = await _apiService.getCarByLicensePlate(spz);
      if (mounted) {
        setState(() {
          _car = car;
          _message = car != null ? '' : 'Car not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _car = null;
          _message = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _spzController.removeListener(_onSpzChangeOrFocus);
    _spzFocusNode.removeListener(_onSpzChangeOrFocus);
    _spzController.dispose();
    _spzFocusNode.dispose();
    _isDialOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double appBarTitleFontSize = 35.0;
    const double userNameFontSize = 14.0;
    bool showCustomPHA = _spzController.text.isEmpty && !_spzFocusNode.hasFocus;
    Color labelTextColor;
    if (showCustomPHA) {
      labelTextColor = Colors.transparent;
    } else if (_spzFocusNode.hasFocus) {
      labelTextColor = Theme.of(context).primaryColor;
    } else {
      labelTextColor = Theme.of(context).hintColor;
    }

    return Scaffold(
      appBar: AppBar(
        leading: _isAppbarExitEnabled
            ? Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: InkWell(
            onTap: _navigateToPinEntry,
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: 'Exit to PIN Entry',
              preferBelow: true,
              verticalOffset: 30,
              child: Transform.scale(
                scaleX: -1.0,
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFF004B81),
                  size: 24.0,
                ),
              ),
            ),
          ),
        )
            : null,
        title: Column(
          children: [
            const Text(
              'De Bondt - SPZ',
              style: TextStyle(
                fontSize: appBarTitleFontSize,
                fontWeight: FontWeight.normal,
                color: Color(0xFF004B81),
              ),
            ),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: userNameFontSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'User:  ${widget.userName}',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (showCustomPHA)
                                IgnorePointer(
                                  child: Text(
                                    'Enter SPZ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              TextField(
                                controller: _spzController,
                                focusNode: _spzFocusNode,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 25),
                                inputFormatters: [UpperCaseTextFormatter()],
                                decoration: InputDecoration(
                                  labelText: 'Enter SPZ',
                                  labelStyle: TextStyle(
                                    fontSize: 20,
                                    color: labelTextColor,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  floatingLabelAlignment: FloatingLabelAlignment.start,
                                  border: const OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  suffixIcon: _spzController.text.isEmpty
                                      ? null
                                      : Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _spzController.clear();
                                        if (mounted) {
                                          setState(() {
                                            _car = null;
                                            _message = '';
                                          });
                                        }
                                        _spzFocusNode.requestFocus();
                                      },
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.fromLTRB(20, 20, 10, 20),
                                ),
                                onSubmitted: (_) => _searchCar(),
                                textInputAction: TextInputAction.search,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _searchCar,
                      child: const Text('Search'),
                    ),
                    const SizedBox(height: 24),
                    if (_message.isNotEmpty)
                      SelectableText(
                        _message,
                        style: TextStyle(
                          color: _car == null && _message != 'Searching...' ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (_car != null)
                      Center(
                        child: Card(
                          margin: const EdgeInsets.only(top: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Table(
                              columnWidths: {
                                0: IntrinsicColumnWidth(),
                                1: FixedColumnWidth(150),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                _buildTableRow('SPZ:', _car!.carLicPlate),
                                _buildTableRow('Details:', _car!.carDetails),
                                _buildTableRow('Color:', _car!.carColor),
                                _buildTableRow('Owner:', '${_car!.ownerSurname} ${_car!.ownerName}'),
                                TableRow(
                                  children: [
                                    _buildLabelCell('Phone:'),
                                    GestureDetector(
                                      onTap: () async {
                                        final phone = _car!.ownerPhone.replaceAll(' ', '');
                                        if (phone.isEmpty) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('No phone number available.')),
                                            );
                                          }
                                          return;
                                        }
                                        final Uri uri = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not launch phone app for $phone')),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 20.0, bottom: 4.0, top: 4.0),
                                        child: Text(
                                          _car!.ownerPhone.isEmpty ? '-' : _car!.ownerPhone,
                                          style: TextStyle(
                                            fontSize: globals.fontSize,
                                            color: _car!.ownerPhone.isEmpty
                                                ? Theme.of(context).textTheme.bodyLarge?.color
                                                : const Color(0xFF004B81),
                                            decoration: _car!.ownerPhone.isEmpty
                                                ? TextDecoration.none
                                                : TextDecoration.none,
                                            fontWeight: _car!.ownerPhone.isEmpty
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                top: BorderSide(
                  color: Colors.blue[100]!,
                  width: 1.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            child: const Text(
              '© 2025 ROBCON s.r.o.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0x99004B81),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: _isMenuEnabled
          ? Padding(
        padding: const EdgeInsets.only(right: 2, bottom: 22),
        child: SpeedDial(
          icon: Icons.menu,
          activeIcon: Icons.close,
          spacing: 3,
          spaceBetweenChildren: 8,
          openCloseDial: _isDialOpen,
          tooltip: 'Menu',
          children: [
            SpeedDialChild(
              child: const Icon(Icons.search),
              label: 'Search SPZ',
              onTap: () {
                _isDialOpen.value = false;
                _spzFocusNode.requestFocus();
              },
            ),
            if (_canEditRecords)
              SpeedDialChild(
                child: const Icon(Icons.edit_note),
                label: 'Edit Records',
                onTap: () {
                  _isDialOpen.value = false;
                  _navigateToCarManagementScreen();
                },
              ),
            SpeedDialChild(
              child: Transform.scale(
                scaleX: -1.0,
                child: const Icon(Icons.logout),
              ),
              label: 'Exit to PIN',
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              onTap: () {
                _isDialOpen.value = false;
                _navigateToPinEntry();
              },
            ),
          ],
        ),
      )
          : null,
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 4.0, top: 4.0),
          child: SelectableText(
            value.isEmpty ? '-' : value,
            style: TextStyle(fontSize: globals.fontSize),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Padding _buildLabelCell(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(fontSize: globals.fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}