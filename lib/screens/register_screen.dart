import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  final _ageController = TextEditingController(); // NEW: Age Controller

  String _bloodGroup = "A+";
  String _gender = "Male";
  String _userType = "Donor";
  bool _loading = false;
  bool _isUnderage = false; // To track donor eligibility

  String? _selectedDistrict;
  String? _selectedCity;

  final Map<String, List<String>> _locations = {
    "Dhaka": ["Dhaka City", "Savar", "Dhamrai", "Keraniganj", "Tongi"],
    "Chittagong": [
      "Chittagong City",
      "Hathazari",
      "Sitakunda",
      "Patiya",
      "Sandwip",
    ],
    "Gazipur": ["Gazipur City", "Kaliakair", "Kapasia", "Sreepur", "Kaliganj"],
  };

  // Logic to check age eligibility
  void _checkAge(String value) {
    int? age = int.tryParse(value);
    if (age != null && age < 18) {
      setState(() {
        _isUnderage = true;
        _userType = "Non-Donor"; // Force Non-Donor status
      });
    } else {
      setState(() {
        _isUnderage = false;
      });
    }
  }

  Future<void> _register() async {
    int? age = int.tryParse(_ageController.text);

    if (_selectedDistrict == null || _selectedCity == null || age == null) {
      _showError("Please complete all details, including age");
      return;
    }

    setState(() => _loading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _pass.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('donor')
          .doc(cred.user!.uid)
          .set({
            "uid": cred.user!.uid,
            "displayName": _name.text.trim(),
            "email": _email.text.trim(),
            "phone": _phone.text.trim(),
            "age": age, // Saved to database
            "bloodGroup": _bloodGroup,
            "gender": _gender,
            "userType": _userType,
            "district": _selectedDistrict,
            "city": _selectedCity,
            "lastDonationDate": Timestamp.fromDate(DateTime(2000)),
            "createdAt": FieldValue.serverTimestamp(),
            "lat": 23.8103,
            "lng": 90.4125,
          });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join the Network"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _field(_name, "Full Name", Icons.person),
            _field(_email, "Email Address", Icons.email),
            _field(_pass, "Password", Icons.lock, obscure: true),
            _field(_phone, "Phone Number", Icons.phone),

            // --- AGE FIELD WITH LOGIC ---
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                onChanged: _checkAge,
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: _dropdown("Gender", _gender, [
                    "Male",
                    "Female",
                    "Other",
                  ], (v) => setState(() => _gender = v!)),
                ),
                const SizedBox(width: 15),
                // --- USER TYPE DROPDOWN (Disabled if Underage) ---
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _userType,
                    decoration: InputDecoration(
                      labelText: "Account Type",
                      border: const OutlineInputBorder(),
                      enabled: !_isUnderage, // Grey out if under 18
                    ),
                    items: ["Donor", "Non-Donor"]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: _isUnderage
                        ? null
                        : (v) => setState(() => _userType = v!),
                  ),
                ),
              ],
            ),

            if (_isUnderage)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Note: You must be 18+ to register as a Donor.",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 15),
            _dropdown("Blood Group", _bloodGroup, [
              "A+",
              "A-",
              "B+",
              "B-",
              "O+",
              "O-",
              "AB+",
              "AB-",
            ], (v) => setState(() => _bloodGroup = v!)),

            const Divider(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Location",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "District",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              value: _selectedDistrict,
              items: _locations.keys
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedDistrict = value;
                _selectedCity = null;
              }),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "City",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              value: _selectedCity,
              items: _selectedDistrict == null
                  ? []
                  : _locations[_selectedDistrict]!
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
              onChanged: (value) => setState(() => _selectedCity = value),
            ),

            const SizedBox(height: 35),
            _loading
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                    ),
                    child: const Text(
                      "COMPLETE REGISTRATION",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String l,
    IconData i, {
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items
        .map((i) => DropdownMenuItem(value: i, child: Text(i)))
        .toList(),
    onChanged: onChanged,
  );
}
