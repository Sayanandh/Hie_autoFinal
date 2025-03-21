import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/navigation_service.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleRegNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _commercialRegNumberController = TextEditingController();

  String _selectedVehicleType = 'Four Wheeler';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _vehicleCapacityController.dispose();
    _licenseNumberController.dispose();
    _vehicleRegNumberController.dispose();
    _insuranceNumberController.dispose();
    _commercialRegNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final registrationData = {
      'fullname': {
        'firstname': _firstNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
      },
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'vehicle': {
        'color': _vehicleColorController.text.trim(),
        'plate': _vehiclePlateController.text.trim(),
        'capacity': int.parse(_vehicleCapacityController.text.trim()),
        'vehicleType': _selectedVehicleType,
      },
      'verification': {
        'LicenseNumber': _licenseNumberController.text.trim(),
        'VehicleRegistrationNumber': _vehicleRegNumberController.text.trim(),
        'InsuranceNumber': _insuranceNumberController.text.trim(),
        'CommertialRegistrationNumber': _commercialRegNumberController.text.trim(),
      },
    };

    try {
      await authProvider.register(registrationData);

      if (!mounted) return;

      NavigationService.navigateTo(
        AppRoutes.otp,
        arguments: {'email': _emailController.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Captain'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Three Wheeler',
                      child: Text('Three Wheeler'),
                    ),
                    DropdownMenuItem(
                      value: 'Four Wheeler',
                      child: Text('Four Wheeler'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _vehicleColorController,
                  labelText: 'Vehicle Color',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _vehiclePlateController,
                  labelText: 'Vehicle Plate Number',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle plate number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _vehicleCapacityController,
                  labelText: 'Vehicle Capacity',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle capacity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verification Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _licenseNumberController,
                  labelText: 'License Number',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter license number';
                    }
                    if (value.length < 14) {
                      return 'License number must be at least 14 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _vehicleRegNumberController,
                  labelText: 'Vehicle Registration Number',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle registration number';
                    }
                    if (value.length < 4) {
                      return 'Registration number must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _insuranceNumberController,
                  labelText: 'Insurance Number',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter insurance number';
                    }
                    if (value.length < 5) {
                      return 'Insurance number must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _commercialRegNumberController,
                  labelText: 'Commercial Registration Number',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter commercial registration number';
                    }
                    if (value.length < 4) {
                      return 'Commercial registration number must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Register'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    NavigationService.navigateTo(AppRoutes.login);
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 