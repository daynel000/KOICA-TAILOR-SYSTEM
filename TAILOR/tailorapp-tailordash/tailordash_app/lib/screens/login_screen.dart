import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../session.dart';
import '../main.dart'; // To access MainNavigationScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  bool _isLogin = true;
  bool _isLoading = false;

  // Form Fields
  String _email = '';
  String _password = '';
  String _fullName = '';
  String _shopName = '';
  String _phone = '';
  String _address = '';

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;
      if (_isLogin) {
        data = await _apiService.login(_email, _password);
      } else {
        data = await _apiService.register({
          'email': _email,
          'password': _password,
          'full_name': _fullName,
          'shop_name': _shopName,
          'phone_number': _phone,
          'address': _address,
        });
      }

      // Save session
      await AppSession.saveSession(
        userId: data['user_id'],
        profileId: data['profile_id'],
        fullName: data['full_name'],
        shopName: data['shop_name'],
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cut, size: 80, color: AppTheme.primaryPurple),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Login to Tailor Dashboard' : 'Join as a Professional Tailor',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  if (!_isLogin) ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => _fullName = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.store)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => _shopName = v!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                    onSaved: (v) => _email = v!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                    validator: (v) => v!.isEmpty || v.length < 6 ? 'Min 6 characters' : null,
                    onSaved: (v) => _password = v!,
                  ),
                  const SizedBox(height: 16),

                  if (!_isLogin) ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: Icon(Icons.phone)),
                      onSaved: (v) => _phone = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Shop Address (Optional)', prefixIcon: Icon(Icons.location_on)),
                      onSaved: (v) => _address = v ?? '',
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isLogin ? "Don't have an account? Register" : 'Already have an account? Login',
                      style: const TextStyle(color: AppTheme.primaryGreen),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
