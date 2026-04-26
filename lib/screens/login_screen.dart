import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for DB check
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance; // Added Firestore instance
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  // --- 1. UNIFIED NAVIGATION LOGIC (THE FIX) ---
  // This ensures every user has a profile before seeing the dashboard
  Future<void> _handlePostAuthNavigation() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if donor profile exists in Firestore
      DocumentSnapshot donorDoc = await _db
          .collection('donor')
          .doc(user.uid)
          .get();

      if (mounted) {
        if (donorDoc.exists) {
          // Profile exists, go to Dashboard/Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Profile missing (e.g., first-time Google login)
          // Redirect to Register/Complete Profile Screen
          _showInfo("Please complete your profile details first.");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }
      }
    } catch (e) {
      _showError("Database Error: Could not verify profile status.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. UPDATED LOGIN HANDLERS ---

  Future<void> _handleLogin() async {
    String input = _idController.text.trim();
    if (input.isEmpty) {
      _showError("Please enter your email or phone number");
      return;
    }

    if (input.contains('@')) {
      _loginEmail(input);
    } else if (RegExp(r'^[0-9+]+$').hasMatch(input)) {
      _verifyPhoneNumber(input);
    } else {
      _showError("Please enter a valid email or phone number");
    }
  }

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
      await _handlePostAuthNavigation(); // Replaced _navigateToHome
    } catch (e) {
      _showError("Login Failed: Incorrect email or password");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPhoneNumber(String phone) async {
    setState(() => _isLoading = true);
    String formattedPhone = phone.startsWith('+') ? phone : "+88$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        await _handlePostAuthNavigation();
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
      await _handlePostAuthNavigation(); // Replaced _navigateToHome
    } catch (e) {
      _showError("Google Login Failed");
      setState(() => _isLoading = false);
    }
  }

  // --- UI & DIALOGS ---

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
                await _handlePostAuthNavigation();
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

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showInfo(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));

  // Build method and decorators remain the same as your original code
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
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Email or Phone Number", Icons.person),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Password", Icons.lock),
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
