import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController    = TextEditingController();
  final _shopNameController    = TextEditingController();
  final _usernameController    = TextEditingController();
  final _emailController       = TextEditingController();
  final _phoneController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPwdController  = TextEditingController();

  bool _obscurePassword  = true;
  bool _obscureConfirm   = true;
  bool _isLoading        = false;

  /// Selected role: 'customer' or 'tailor'
  String _selectedRole = 'customer';

  static const _brandNavy  = Color(0xFF132238);
  static const _brandGold  = Color(0xFFD49228);
  static const _borderColor = Color(0xFFDFE4EA);
  static const _hintColor   = Color(0xFF9AA5B5);
  static const _bgColor     = Color(0xFFFAFAFC);

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        fullName:        _fullNameController.text.trim(),
        shopName:        _selectedRole == 'tailor' ? _shopNameController.text.trim() : null,
        username:        _usernameController.text.trim(),
        email:           _emailController.text.trim(),
        phone:           _phoneController.text.trim(),
        password:        _passwordController.text,
        confirmPassword: _confirmPwdController.text,
        role:            _selectedRole,
      );

      if (!mounted) return;
      _showSnack('Account created! Please check your email to verify before logging in.', _brandNavy);
      Navigator.of(context).pop(); // Go back to login
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Reusable input decoration ────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _hintColor, fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: prefixIcon,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _brandNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  TextStyle get _inputStyle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _brandNavy,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _brandNavy, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _brandNavy,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────────
                Text(
                  'Join Tailor Connect',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _brandNavy,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in your details to get started.',
                  style: GoogleFonts.inter(fontSize: 14, color: _hintColor),
                ),

                const SizedBox(height: 24),

                // ── Role Selector ─────────────────────────────────────────
                Text(
                  'Register as',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _brandNavy,
                  ),
                ),
                const SizedBox(height: 10),
                _RoleSelector(
                  selected: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),

                const SizedBox(height: 22),

                // ── Full Name ─────────────────────────────────────────────
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Full Name',
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: Color(0xFF4A5568), size: 21),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),

                // ── Shop Name (Shown only when Tailor is selected) ────────
                if (_selectedRole == 'tailor') ...[
                  TextFormField(
                    controller: _shopNameController,
                    textInputAction: TextInputAction.next,
                    style: _inputStyle,
                    decoration: _inputDecoration(
                      hint: 'Shop / Business Name',
                      prefixIcon: const Icon(Icons.storefront_outlined,
                          color: Color(0xFF4A5568), size: 21),
                    ),
                    validator: (v) {
                      if (_selectedRole == 'tailor') {
                        if (v == null || v.trim().isEmpty) {
                          return 'Shop name is required for tailors';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Username ──────────────────────────────────────────────
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Username',
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF4A5568), size: 21),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (v.trim().length < 3) return 'Minimum 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Email ─────────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Color(0xFF4A5568), size: 21),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailReg = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
                    if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Phone ─────────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Phone Number (optional)',
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: Color(0xFF4A5568), size: 21),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF4A5568), size: 21),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF4A5568),
                        size: 21,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Confirm Password ──────────────────────────────────────
                TextFormField(
                  controller: _confirmPwdController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  style: _inputStyle,
                  decoration: _inputDecoration(
                    hint: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF4A5568), size: 21),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF4A5568),
                        size: 21,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ── Register Button ───────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Already have account ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _hintColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF386FA4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role Selector Widget ──────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleTile(
            label: 'Customer',
            description: 'Find & book tailors',
            icon: Icons.person_rounded,
            value: 'customer',
            selected: selected == 'customer',
            onTap: () => onChanged('customer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleTile(
            label: 'Tailor',
            description: 'Offer your services',
            icon: Icons.content_cut_rounded,
            value: 'tailor',
            selected: selected == 'tailor',
            onTap: () => onChanged('tailor'),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF132238);
    const gold = Color(0xFFD49228);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? navy : const Color(0xFFDFE4EA),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: navy.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? gold : const Color(0xFF758195),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : navy,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: selected
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF9AA5B5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
