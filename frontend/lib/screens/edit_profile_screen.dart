import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl  = TextEditingController(text: user?['name']  ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    _bioCtrl   = TextEditingController(text: user?['bio']   ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final updatedUser = await authProvider.authService.updateProfile(
        name:  _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio:   _bioCtrl.text.trim(),
      );
      authProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final user = context.watch<AuthProvider>().currentUser;
    final String? photoUrl = user?['profilePicture'];
    final String name = user?['name'] ?? 'C';

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                  )
                : Text('Save', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar (display only)
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: photoUrl == null
                            ? (c.primaryGradient ??
                                LinearGradient(colors: [c.primary, c.accent]))
                            : null,
                        boxShadow: [
                          BoxShadow(color: c.primary.withOpacity(0.35), blurRadius: 18),
                        ],
                      ),
                      child: photoUrl != null
                          ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Photo from Google — updated automatically',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Email (read-only)
              _buildReadOnlyField(
                label: 'Email',
                value: user?['email'] ?? '',
                icon: Icons.email_outlined,
                c: c,
                theme: theme,
              ),

              const SizedBox(height: 16),

              // Name
              _buildField(
                controller: _nameCtrl,
                label: 'Display Name',
                icon: Icons.person_outline,
                c: c,
                theme: theme,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),

              const SizedBox(height: 16),

              // Phone
              _buildField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                c: c,
                theme: theme,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Bio
              _buildField(
                controller: _bioCtrl,
                label: 'Bio',
                icon: Icons.info_outline,
                c: c,
                theme: theme,
                maxLines: 3,
                hint: 'Tell the world about yourself...',
              ),

              const SizedBox(height: 36),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColors c,
    required ThemeData theme,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: c.textSecondary),
        filled: true,
        fillColor: c.secondary.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: c.textSecondary.withOpacity(0.6), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required AppColors c,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 14, color: c.textSecondary.withOpacity(0.5)),
        ],
      ),
    );
  }
}
