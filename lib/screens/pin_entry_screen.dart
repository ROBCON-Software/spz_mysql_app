import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart'; // Ensure HomeScreen is imported
import '../globals.dart' as globals;

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPinComplete = false;
  int _failedAttempts = 0;

  bool _isInPenaltyCooldown = false;
  String _originalErrorMessageOnCooldown = '';

  bool _isLockedOut = false;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;
  static const int _lockoutDurationSeconds = 30;

  static const _validationTimeout = Duration(seconds: 10);
  static const _maxAttempts = 3;
  static const _failedAttemptDelay = Duration(seconds: 5);

  void _checkPinLength() {
    final isComplete = _pinController.text.length == globals.pinLength;
    if (_isPinComplete != isComplete) {
      if (mounted) {
        setState(() {
          _isPinComplete = isComplete;
        });
      }
    }
  }

  void _startLockoutTimer() {
    if (!mounted) return;
    setState(() {
      _isLockedOut = true;
      _isLoading = false;
      _pinController.clear();
      _lockoutSecondsRemaining = _lockoutDurationSeconds;
      _errorMessage = 'Maximum attempts reached.\nPlease try again in $_lockoutSecondsRemaining seconds.';
    });

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutSecondsRemaining--;
        if (_lockoutSecondsRemaining > 0) {
          _errorMessage = 'Maximum attempts reached.\nPlease try again in $_lockoutSecondsRemaining seconds.';
        } else {
          timer.cancel();
          _resetAfterLockout();
        }
      });
    });
  }

  void _resetAfterLockout() {
    if (!mounted) return;
    setState(() {
      _isLockedOut = false;
      _failedAttempts = 0;
      _errorMessage = '';
      _pinController.clear();
      _isLoading = false;
      _isInPenaltyCooldown = false;
      _isPinComplete = false;
      _checkPinLength();
    });
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      _pinFocusNode.requestFocus();
    }
  }

  Future<void> _validatePin() async {
    if (_isLockedOut || _isInPenaltyCooldown || _isLoading) return;

    final enteredPin = _pinController.text;
    if (enteredPin.length < globals.pinLength) {
      if (mounted) setState(() => _errorMessage = 'PIN must be ${globals.pinLength} digits.');
      _pinFocusNode.requestFocus();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final url = Uri.parse('${globals.baseApiUrl}/validate_pin.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'pin_number': enteredPin}),
      ).timeout(_validationTimeout);

      if (!mounted) {
        if (_isLoading) _isLoading = false;
        return;
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          _failedAttempts = 0;

          final dynamic isAdminRaw = responseBody['is_admin'];
          final dynamic userName = responseBody['user_name'];

          int isAdmin = 0; // Default to non-admin

          if (isAdminRaw is int) {
            isAdmin = isAdminRaw;
          } else if (isAdminRaw is String) {
            isAdmin = int.tryParse(isAdminRaw) ?? 0;
          }

          // Navigate to HomeScreen, passing both isAdminFlag and userName
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                isAdminFlag: isAdmin,
                userName: userName?.toString() ?? 'User', // Pass username with fallback
              ),
            ),
          );
          return;
        } else {
          _failedAttempts++;
          final bool isMaxAttemptsReached = _failedAttempts >= _maxAttempts;
          final String serverMessage = responseBody['message'] as String? ?? '';

          if (isMaxAttemptsReached) {
            if (mounted) setState(() => _isLoading = false);
            _startLockoutTimer();
            return;
          }

          String part1ErrorMessage = serverMessage.isNotEmpty && !serverMessage.toLowerCase().contains("invalid pin")
              ? serverMessage
              : 'Invalid PIN.';
          String part2ErrorMessage = '${_maxAttempts - _failedAttempts} attempts remaining.';
          String currentErrorMessage = '$part1ErrorMessage\n$part2ErrorMessage';

          if (mounted) {
            setState(() {
              _errorMessage = currentErrorMessage;
              _isLoading = false;
            });
          }
          _pinController.clear();
          _pinFocusNode.requestFocus();

          if (_failedAttempts > 0) {
            _originalErrorMessageOnCooldown = currentErrorMessage;
            if (mounted) {
              setState(() {
                _isInPenaltyCooldown = true;
                _errorMessage = "$part1ErrorMessage\nPlease wait...";
              });
            }
            await Future.delayed(_failedAttemptDelay);
            if (mounted) {
              setState(() {
                _isInPenaltyCooldown = false;
                _errorMessage = _originalErrorMessageOnCooldown;
                _checkPinLength();
              });
              if (!_isLockedOut) {
                _pinFocusNode.requestFocus();
              }
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error (${response.statusCode}). Please try again later.';
            _isLoading = false;
          });
        }
        _pinController.clear();
        _pinFocusNode.requestFocus();
      }
    } on http.ClientException catch (e) {
      if (mounted) setState(() { _errorMessage = 'Network error: ${e.message}'; _isLoading = false; });
    } on TimeoutException {
      if (mounted) setState(() { _errorMessage = 'Request timed out. Please try again.'; _isLoading = false; });
    } on FormatException {
      if (mounted) setState(() { _errorMessage = 'Invalid server response format.'; _isLoading = false; });
      _pinController.clear(); _pinFocusNode.requestFocus();
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Unexpected error: ${e.toString()}'; _isLoading = false; });
    } finally {
      if (mounted && _isLoading && !_isLockedOut && !_isInPenaltyCooldown) {
        final currentRoute = ModalRoute.of(context);
        if (currentRoute != null && currentRoute.isCurrent) {
          setState(() { _isLoading = false; });
        }
      }
      if (mounted) _checkPinLength();
    }
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_checkPinLength);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.removeListener(_checkPinLength);
    _pinController.dispose();
    _pinFocusNode.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double appBarTitleFontSize = 35.0;
    String hintText = List.generate(globals.pinLength, (_) => '-').join();
    const double pinFieldMaxWidth = 280.0;
    const double okButtonWidth = 150.0;

    final bool isActuallyLoadingForApi = _isLoading && !_isInPenaltyCooldown && !_isLockedOut;
    final bool isControlsEnabled = !_isLockedOut && !_isInPenaltyCooldown && _failedAttempts < _maxAttempts && !isActuallyLoadingForApi;
    final bool isTextFieldActuallyEnabled = !_isLockedOut && !_isInPenaltyCooldown && _failedAttempts < _maxAttempts;
    final bool isOkButtonEnabled = _isPinComplete && isControlsEnabled;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('De Bondt - SPZ', style: TextStyle(fontSize: appBarTitleFontSize, fontWeight: FontWeight.normal, color: Color(0xFF004B81))),
        centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Column(
        children: [
          Expanded( // This takes up available vertical space for the main content
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // const SizedBox(height: 20), // Optional top spacing

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text('Enter Your PIN', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: pinFieldMaxWidth),
                      child: TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        maxLength: globals.pinLength,
                        enabled: isTextFieldActuallyEnabled,
                        style: const TextStyle(fontSize: 32, letterSpacing: 20.0, fontWeight: FontWeight.bold),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.5)),
                          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                          hintText: hintText,
                          hintStyle: TextStyle(fontSize: 32, letterSpacing: 20.0, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.bold),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          semanticCounterText: 'PIN digits remaining',
                        ),
                        onChanged: (value) {
                          if (_errorMessage.isNotEmpty && !_isInPenaltyCooldown && !_isLockedOut) {
                            if (mounted) setState(() => _errorMessage = '');
                          }
                          _checkPinLength();
                        },
                        onSubmitted: (_) => isOkButtonEnabled ? _validatePin() : null,
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
                        child: Text(_errorMessage, style: TextStyle(color: (_isLockedOut || _isInPenaltyCooldown || _failedAttempts >= _maxAttempts) ? Colors.orange[800] : Colors.red, fontSize: 18, fontWeight: (_isLockedOut || _isInPenaltyCooldown || _failedAttempts >= _maxAttempts) ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 25),
                    if (isActuallyLoadingForApi)
                      const Center(child: CircularProgressIndicator())
                    else if (!_isLockedOut && !_isInPenaltyCooldown)
                      SizedBox(
                        width: okButtonWidth,
                        child: ElevatedButton(
                          onPressed: isOkButtonEnabled ? _validatePin : null,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18)),
                          child: const Text('OK'),
                        ),
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ), // End of Expanded

          // ---- ADD THE FOOTER HERE ----
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50], // Or Theme.of(context).colorScheme.surfaceVariant or similar
              border: Border(
                top: BorderSide(
                  color: Colors.blue[100]!, // Or a theme-based color
                  width: 1.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2), // Adjust padding as needed
            alignment: Alignment.center,
            child: const Text(
              '© 2025 ROBCON s.r.o.', // Your footer text
              style: TextStyle(
                fontSize: 14, // Adjust size as needed
                color: Color(0x99004B81), // Or a theme-based color
              ),
            ),
          ),
        ],
      ),
    );
  }
}