import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/navigation_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/providers/captain_provider.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  
  const OtpVerificationPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _logger = Logger('OtpVerificationPage');

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    _logger.info('Starting OTP verification process');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final captainProvider = Provider.of<CaptainProvider>(context, listen: false);
    
    try {
      await authProvider.verifyOTP(
        widget.email,
        _otpController.text.trim(),
      );

      _logger.info('OTP verification completed');
      _logger.info('Error status: ${authProvider.error}');
      _logger.info('Is authenticated: ${authProvider.isAuthenticated}');

      if (authProvider.error != null) {
        if (mounted) {
          _logger.warning('Showing error: ${authProvider.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.error!)),
          );
        }
      } else {
        // Update CaptainProvider with the authenticated captain
        if (authProvider.captain != null) {
          await captainProvider.setCaptain(authProvider.captain!);
        }
        
        if (mounted) {
          _logger.info('Navigation to home page');
          await NavigationService.navigateToAndRemoveUntil(AppRoutes.home);
          _logger.info('Navigation completed');
        }
      }
    } catch (e) {
      _logger.severe('Error during OTP verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 80,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verify Your Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the OTP sent to ${widget.email}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        prefixIcon: Icon(Icons.lock_clock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Verify OTP'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 