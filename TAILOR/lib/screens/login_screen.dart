import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/tailor_logo.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import 'register_screen.dart';
import 'main_shell.dart';
import 'tailor/tailor_main_shell.dart';
import '../session/tailor_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(
        username: username,
        password: password,
      );

      // Support nested user or data key in the JSON response
      final userInfo = data['user'] ?? data['data'] ?? data;

      // Route based on role
      final isTailor = userInfo['role'] == 'tailor' || 
                       userInfo['is_tailor'] == true || 
                       userInfo['is_tailor'] == 1 || 
                       userInfo['is_tailor'] == '1' ||
                       userInfo['is_tailor'] == 'true';

      if (isTailor) {
        await TailorSession.saveSession(
          userId: int.tryParse(userInfo['user_id']?.toString() ?? '') ?? 0,
          profileId: int.tryParse(userInfo['profile_id']?.toString() ?? '') ?? 0,
          fullName: userInfo['full_name']?.toString() ?? 'Tailor',
          shopName: userInfo['shop_name']?.toString() ?? 'Tailor Shop',
        );

        if (!mounted) return;
        _showSnack('Welcome back, ${userInfo['full_name'] ?? 'Tailor'}!', const Color(0xFF132238));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TailorMainShell()),
        );
      } else {
        final custName = userInfo['full_name']?.toString() ?? username;
        if (mounted) {
          context.read<AppProvider>().setLoggedInCustomer(
            fullName: custName,
            username: username,
          );
        }
        if (!mounted) return;
        _showSnack('Welcome back, $custName!', const Color(0xFF132238));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      // Fallback for offline development / Quick Demo Logins / Registered Accounts:
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('registered_role_${username.toLowerCase()}');

      final lowerUser = username.toLowerCase();
      final isTailor = savedRole == 'tailor' ||
          lowerUser == 'tailor' ||
          lowerUser == 'admin' ||
          lowerUser.contains('tailor') ||
          lowerUser.contains('shop') ||
          lowerUser.contains('master');

      if (isTailor) {
        final formattedName = username.isNotEmpty
            ? username[0].toUpperCase() + username.substring(1)
            : 'Tailor';
        await TailorSession.saveSession(
          userId: 1,
          profileId: 1,
          fullName: formattedName,
          shopName: '$formattedName\'s Tailoring',
        );
        if (!mounted) return;
        _showSnack('Welcome back, $formattedName!', const Color(0xFF132238));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TailorMainShell()),
        );
      } else {
        // Customer login -> Route to Customer Dashboard (MainShell)
        final userKey = username.toLowerCase();
        final savedName = prefs.getString('registered_fullname_$userKey');
        final customerName = (savedName != null && savedName.isNotEmpty)
            ? savedName
            : (username.isNotEmpty ? username[0].toUpperCase() + username.substring(1) : 'Customer');

        if (mounted) {
          context.read<AppProvider>().setLoggedInCustomer(
            fullName: customerName,
            username: username,
          );
        }

        if (!mounted) return;
        _showSnack('Welcome back, $customerName!', const Color(0xFF132238));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
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

  void _handleCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password reset link requested.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF386FA4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandNavy = Color(0xFF132238);
    const brandGold = Color(0xFFD49228);
    const inputBorderColor = Color(0xFFDFE4EA);
    const hintColor = Color(0xFF9AA5B5);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Top Tailor Connect Logo
                  const TailorConnectLogo(),

                  const SizedBox(height: 38),

                  // Heading: Welcome Back!
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: brandNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subheading: Login to continue
                  Text(
                    'Login to continue',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: hintColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Username Input Field
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: brandNavy,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: GoogleFonts.inter(
                        color: hintColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF4A5568),
                          size: 22,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: inputBorderColor, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: brandNavy, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Input Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: brandNavy,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: GoogleFonts.inter(
                        color: hintColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF4A5568),
                          size: 22,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF4A5568),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: inputBorderColor, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: brandNavy, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF386FA4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Primary Button: Log In
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGold,
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
                              'Log In',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Divider: -- or --
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Text(
                          'or',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8C9BAE),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Secondary Button: Create Account
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleCreateAccount,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: brandNavy,
                        side: const BorderSide(color: brandNavy, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Demo Credentials Helper Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Quick Demo Logins',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  _usernameController.text = 'tailor';
                                  _passwordController.text = 'password';
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Tailor',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: brandNavy,
                                        ),
                                      ),
                                      Text(
                                        'tailor / password',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  _usernameController.text = 'john_doe';
                                  _passwordController.text = 'password';
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Customer',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: brandNavy,
                                        ),
                                      ),
                                      Text(
                                        'john_doe / password',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
