import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _idController = TextEditingController(); // Email or Phone
  final _passController = TextEditingController();
  bool _isLoading = false;

  // --- SMART LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    String input = _idController.text.trim();

    if (input.isEmpty) {
      _showError("Please enter your email or phone number");
      return;
    }

    // Logic: If it contains '@', it's an email. If it's numeric, it's a phone number.
    if (input.contains('@')) {
      _loginEmail(input);
    } else if (RegExp(r'^[0-9+]+$').hasMatch(input)) {
      _verifyPhoneNumber(input);
    } else {
      _showError("Please enter a valid email or phone number");
    }
  }

  // --- 1. EMAIL LOGIN ---
  Future<void> _loginEmail(String email) async {
    if (_passController.text.isEmpty) {
      _showError("Password is required for email login");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passController.text.trim(),
      );
      _navigateToHome();
    } catch (e) {
      _showError("Login Failed: Incorrect email or password");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. PHONE LOGIN (OTP) ---
  Future<void> _verifyPhoneNumber(String phone) async {
    setState(() => _isLoading = true);
    // Ensure phone starts with +88 if it doesn't already
    String formattedPhone = phone.startsWith('+') ? phone : "+88$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _navigateToHome();
      },
      verificationFailed: (e) {
        _showError("Phone Auth Failed: ${e.message}");
        setState(() => _isLoading = false);
      },
      codeSent: (String vid, int? resendToken) {
        setState(() => _isLoading = false);
        _showOTPDialog(vid);
      },
      codeAutoRetrievalTimeout: (vid) {},
    );
  }

  // --- 3. FORGOT PASSWORD ---
  Future<void> _resetPassword() async {
    String input = _idController.text.trim();
    if (!input.contains("@")) {
      _showError("Please enter your email address to reset password");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: input);
      _showSuccess("Reset link sent! Check your email.");
    } catch (e) {
      _showError("Error: User not found");
    }
  }

  // --- 4. GOOGLE LOGIN ---
  Future<void> _loginGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final user = await googleSignIn.signIn();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final auth = await user.authentication;
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        ),
      );
      _navigateToHome();
    } catch (e) {
      _showError("Google Login Failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOTPDialog(String vid) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "6-digit code"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: vid,
                  smsCode: otpController.text.trim(),
                );
                await _auth.signInWithCredential(credential);
                Navigator.pop(context);
                _navigateToHome();
              } catch (e) {
                _showError("Invalid OTP code");
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccess(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.bloodtype, size: 80, color: Colors.white),
              const Text(
                "Blood Donor BD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // --- UNIFIED INPUT FIELD ---
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Email or Phone Number", Icons.person),
              ),

              const SizedBox(height: 15),

              // --- PASSWORD FIELD (CLEANED) ---
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Password", Icons.lock),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: _btnStyle(Colors.white, Colors.red.shade900),
                      child: const Text("LOGIN / SEND OTP"),
                    ),

              const SizedBox(height: 20),
              const Text("OR", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _loginGoogle,
                icon: const Icon(
                  Icons.g_mobiledata,
                  color: Colors.white,
                  size: 30,
                ),
                label: const Text(
                  "Sign-In with Google",
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "New Donor? Register Here",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String lbl, IconData ico) => InputDecoration(
    labelText: lbl,
    prefixIcon: Icon(ico, color: Colors.white70),
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white54),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
  );

  ButtonStyle _btnStyle(Color bg, Color fg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
