import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedBlood = "A+";
  bool _loading = false;

  // --- LOCATION DATA (Synced with Register Code) ---
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

  Future<void> _submitRequest() async {
    // 1. Precise Validation
    if (_selectedDistrict == null ||
        _selectedCity == null ||
        _hospitalController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showError("Please complete all details, including location.");
      return;
    }

    setState(() => _loading = true);
    try {
      // 2. Save to 'blood_requests' collection
      await FirebaseFirestore.instance.collection('blood_requests').add({
        "hospitalName": _hospitalController.text.trim(),
        "phone": _phoneController.text.trim(),
        "reason": _reasonController.text.trim(),
        "bloodGroup": _selectedBlood,
        "district": _selectedDistrict, // Saved for targeted alerts
        "city": _selectedCity, // Saved for targeted alerts
        "requestedBy": FirebaseAuth.instance.currentUser?.uid,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Pending",
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Emergency Request Posted! Alerting nearby donors...",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Failed to post request: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text("Post Emergency Request"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Urgent: Fill in the patient's details below.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 25),

            // 1. Blood Group Needed
            DropdownButtonFormField<String>(
              value: _selectedBlood,
              decoration: const InputDecoration(
                labelText: "Blood Group Needed",
                prefixIcon: Icon(Icons.bloodtype, color: Colors.red),
                border: OutlineInputBorder(),
              ),
              items: [
                "A+",
                "A-",
                "B+",
                "B-",
                "O+",
                "O-",
                "AB+",
                "AB-",
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _selectedBlood = v!),
            ),
            const SizedBox(height: 15),

            // 2. District Selection
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
                _selectedCity = null; // Reset city on district change
              }),
            ),
            const SizedBox(height: 15),

            // 3. City Selection (Cascading)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "City / Area",
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

            const Divider(height: 40),

            // 4. Hospital, Phone & Reason
            _field(_hospitalController, "Hospital Name", Icons.local_hospital),
            _field(
              _phoneController,
              "Contact Number",
              Icons.phone,
              type: TextInputType.phone,
            ),
            _field(
              _reasonController,
              "Reason (Short Note)",
              Icons.note_alt,
              maxLines: 2,
            ),

            const SizedBox(height: 30),

            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "BROADCAST REQUEST",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
