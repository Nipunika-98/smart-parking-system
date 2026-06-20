import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/screens/add_vehicle_screen.dart';
import 'package:mobile/screens/change_password_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/view_rates_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/user_service.dart';
import 'package:mobile/services/vehicle_service.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/vehicle_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user == null) {
          userProvider.loadUser(uid);
        }
      }
    });
  }

  Future<void> _showEditPhoneDialog(String currentPhone) async {
    final TextEditingController phoneController = TextEditingController(text: currentPhone);
    phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: phoneController.text.length),
    );

    final uid = _authService.currentUser?.uid;

    if (uid == null) return;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Edit Phone Number',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update your contact number for important session updates.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newPhone = phoneController.text.trim();
                  if (newPhone.isEmpty) {
                    UIUtils.showSnackBar(context, 'Phone number cannot be empty', isError: true);
                    return;
                  }

                  Navigator.pop(dialogContext);
                  try {
                    await _userService.updateUserProfile(uid, {'phoneNumber': newPhone});
                    if (!context.mounted) return;

                    Provider.of<UserProvider>(context, listen: false).loadUser(uid);

                    UIUtils.showSnackBar(
                      context,
                      'Phone number updated successfully',
                      isError: false,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    UIUtils.showSnackBar(
                      context,
                      UIUtils.getFriendlyErrorMessage(e),
                      isError: true,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
  }

  IconData _getVehicleIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('bike') || t.contains('motorcycle')) {
      return Icons.motorcycle;
    } else if (t.contains('three') || t.contains('rickshaw') || t.contains('tuktuk')) {
      return Icons.electric_rickshaw;
    } else if (t.contains('van') || t.contains('shuttle')) {
      return Icons.airport_shuttle;
    }
    return Icons.directions_car;
  }

  void _deleteVehicle(String vehicleId, String plateNumber) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Vehicle'),
            content: Text('Are you sure you want to delete vehicle $plateNumber?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _vehicleService.deleteVehicle(vehicleId);
                    if (!context.mounted) return;
                    UIUtils.showSnackBar(context, 'Vehicle deleted successfully', isError: false);
                  } catch (e) {
                    if (!context.mounted) return;
                    UIUtils.showSnackBar(
                      context,
                      UIUtils.getFriendlyErrorMessage(e),
                      isError: true,
                    );
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body:
          userProvider.isLoading && user == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildHeader(user),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSectionTitle('Personal Information'),
                          _buildPersonalInfoCard(user),
                          const SizedBox(height: 24),

                          _buildSectionHeader('My Vehicles', '+ Add', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                            );
                          }),

                          Consumer<VehicleProvider>(
                            builder: (context, vehicleProvider, child) {
                              if (vehicleProvider.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (vehicleProvider.vehicles.isEmpty) {
                                return const Text('No vehicles added yet.');
                              }
                              return Column(
                                children:
                                    vehicleProvider.vehicles
                                        .map(
                                          (v) => Column(
                                            children: [
                                              _buildVehicleCard(
                                                context,
                                                v.vehicleId,
                                                v.vehiclePlateNo,
                                                v.vehicleType,
                                                isPrimary: v.isPrimary,
                                                icon: _getVehicleIcon(v.vehicleType),
                                                onDelete:
                                                    () => _deleteVehicle(
                                                      v.vehicleId,
                                                      v.vehiclePlateNo,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Settings'),
                          _buildSettingsCard(context),
                          const SizedBox(height: 30),
                          _buildLogoutButton(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF2C3E50),
              child: Icon(Icons.person_outline, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.userId != null ? 'ID: ${user!.userId.substring(0, 8)}...' : '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionInfo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          InkWell(
            onTap: onTap,
            child: Text(
              actionInfo,
              style: const TextStyle(color: Color(0xFF0A2540), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserModel? user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, 'Email', user?.email ?? 'Loading...'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              user?.phoneNumber ?? 'Loading...',
              trailing:
                  user != null
                      ? IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryColor),
                        onPressed: () => _showEditPhoneDialog(user.phoneNumber),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00695C).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00695C), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    String vehicleId,
    String plateNumber,
    String type, {
    required bool isPrimary,
    required IconData icon,
    required VoidCallback onDelete,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plateNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          type,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2648),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'Primary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _buildActionButton(Icons.edit, const Color(0xFF00695C), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddVehicleScreen(
                        vehicleId: vehicleId,
                        plateNumber: plateNumber,
                        vehicleType: type,
                        isPrimary: isPrimary,
                      ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _buildActionButton(Icons.delete_outline, Colors.red, onDelete),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.attach_money,
            'View Rates',
            () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewRatesScreen())),
          ),
          const Divider(height: 1, indent: 60),
          _buildSettingsItem(
            Icons.lock_outline,
            'Change Password',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF00695C), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _authService.signOut();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
          );
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
        ),
        icon: const Icon(Icons.logout, size: 20, color: Colors.red),
        label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
