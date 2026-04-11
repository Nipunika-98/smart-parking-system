import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/vehicle_model.dart';
import 'package:mobile/services/vehicle_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/utils/ui_utils.dart';

class AddVehicleScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleType;
  final String? plateNumber;
  final bool isPrimary;

  const AddVehicleScreen({
    super.key,
    this.vehicleId,
    this.vehicleType,
    this.plateNumber,
    this.isPrimary = false,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  final AuthService _authService = AuthService();

  final TextEditingController plateController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  late bool isPrimary;
  final _plateFocus = FocusNode();

  String? selectedVehicleType;
  bool _isLoading = false;
  bool _isFirstVehicle = false;
  UserModel? _pendingUser;

  @override
  void initState() {
    super.initState();
    plateController.text = widget.plateNumber ?? '';
    typeController.text = widget.vehicleType ?? 'Car';
    selectedVehicleType = widget.vehicleType;
    isPrimary = widget.isPrimary;

    _plateFocus.addListener(() => _onFocusChange(_plateFocus, plateController));

    // Check for pending registration data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserModel) {
        setState(() {
          _pendingUser = args;
          _isFirstVehicle = true;
          isPrimary = true;
        });
      } else {
        _checkIsFirstVehicle();
      }
    });
  }

  void _onFocusChange(FocusNode node, TextEditingController controller) {
    if (node.hasFocus && controller.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!controller.selection.isCollapsed) {
          controller.selection = TextSelection.collapsed(
            offset: controller.selection.extentOffset,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    plateController.dispose();
    typeController.dispose();
    _plateFocus.dispose();
    super.dispose();
  }

  Future<void> _checkIsFirstVehicle() async {
    final user = _authService.currentUser;
    if (user != null) {
      if (widget.vehicleId == null) {
        final vehicles = await _vehicleService.getUserVehicles(user.uid).first;
        if (vehicles.isEmpty) {
          setState(() {
            _isFirstVehicle = true;
            isPrimary = true;
          });
        }
      }
    }
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'Car':
        return Icons.directions_car;
      case 'Bike':
        return Icons.two_wheeler;
      case 'Van':
        return Icons.airport_shuttle;
      case 'Three-Wheel':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }

  Future<void> _submitVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = _authService.currentUser;
        if (user == null) throw Exception('No user logged in');

        if (widget.vehicleId != null) {
          // Update existing
          await _vehicleService.updateVehicle(widget.vehicleId!, {
            'vehiclePlateNo': plateController.text.trim(),
            'vehicleType': selectedVehicleType,
            'isPrimary': isPrimary,
            'userId': user.uid,
          });
        } else {
          // If this is a new registration, save the user profile first
          if (_pendingUser != null) {
            await _authService.createUserProfile(_pendingUser!);
          }

          // Add new vehicle
          VehicleModel newVehicle = VehicleModel(
            vehicleId: '',
            userId: user.uid,
            vehicleType: selectedVehicleType ?? 'Car',
            vehiclePlateNo: plateController.text.trim(),
            isPrimary: isPrimary,
            registrationDate: DateTime.now(),
            isActive: true,
          );
          await _vehicleService.addVehicle(newVehicle);
        }

        if (!mounted) return;
        UIUtils.showSnackBar(
          context,
          widget.vehicleId != null ? 'Vehicle Updated' : 'Vehicle Added',
          isError: false,
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } catch (e) {
        if (!mounted) return;
        UIUtils.showSnackBar(context, UIUtils.getFriendlyErrorMessage(e), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Title
                Text(
                  widget.plateNumber != null ? 'Edit Vehicle' : 'Add Your Vehicle',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.plateNumber != null
                      ? 'Update your vehicle details'
                      : 'Register your vehicle to continue',
                  style: const TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
                ),

                const SizedBox(height: 30),

                // Vehicle Type
                _buildLabel('Vehicle Type'),
                DropdownButtonFormField<String>(
                  value: selectedVehicleType,
                  validator: (value) => value == null ? 'Please select a vehicle type' : null,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    prefixIcon: Icon(
                      selectedVehicleType == null
                          ? Icons.directions_car
                          : _vehicleIcon(selectedVehicleType!),
                      color: const Color(0xFF6E6D74),
                    ),
                    hintText: 'Select Vehicle Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Car', child: Text('Car')),
                    DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'Van', child: Text('Van')),
                    DropdownMenuItem(value: 'Three-Wheel', child: Text('Three-Wheel')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Plate Number
                _buildLabel('Plate Number'),
                TextFormField(
                  key: const ValueKey('plateNumberField'),
                  controller: plateController,
                  focusNode: _plateFocus,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitVehicle(),
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!plateController.selection.isCollapsed) {
                        plateController.selection = TextSelection.collapsed(
                          offset: plateController.selection.extentOffset,
                        );
                      }
                    });
                  },
                  decoration: _inputDecoration(hint: 'ABC-1234', icon: Icons.confirmation_number),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Plate number is required';
                    }

                    final regex = RegExp(r'^[A-Z]{2,3}-\d{4}$');

                    if (!regex.hasMatch(value)) {
                      return 'Invalid format (Example: ABC-1234)';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Primary vehicle switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set as Primary Vehicle',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isFirstVehicle ? Colors.grey : AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isPrimary,
                        thumbColor: WidgetStateProperty.resolveWith<Color>(
                          (states) =>
                              states.contains(WidgetState.selected)
                                  ? (_isFirstVehicle ? Colors.grey : AppColors.primaryColor)
                                  : Colors.grey,
                        ),
                        onChanged:
                            _isFirstVehicle
                                ? null
                                : (value) {
                                  setState(() {
                                    isPrimary = value;
                                  });
                                },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A7C83),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your primary vehicle will be selected by default when creating an account.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // Add Vehicle button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitVehicle,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            widget.vehicleId != null ? 'Update Vehicle' : 'Add Vehicle',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                ),

                const SizedBox(height: 16),

                // Skip
                if (_pendingUser == null)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  // Input decoration
  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.inputBackground,
      prefixIcon: Icon(icon, color: const Color(0xFF6E6D74)),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6E6D74)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
