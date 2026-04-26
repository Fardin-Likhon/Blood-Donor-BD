import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreBookScreen extends StatefulWidget {
  const PreBookScreen({super.key});

  @override
  State<PreBookScreen> createState() => _PreBookScreenState();
}

class _PreBookScreenState extends State<PreBookScreen> {
  final _hospitalController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedBlood = "A+";
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  // --- LOCATION DATA FROM REGISTER CODE ---
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

  Future<void> _submitPreBooking() async {
    // Validation for new location fields
    if (_selectedDistrict == null ||
        _selectedCity == null ||
        _hospitalController.text.isEmpty) {
      _showError("Please complete all details, including location");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Saving to 'pre_bookings' with matching District/City structure
      await FirebaseFirestore.instance.collection('pre_bookings').add({
        "bloodGroup": _selectedBlood,
        "district": _selectedDistrict, // Added
        "city": _selectedCity, // Added
        "hospitalName": _hospitalController.text.trim(),
        "procedureDate": Timestamp.fromDate(_scheduledDate),
        "reason": _reasonController.text.trim(),
        "status": "Active",
        "requestedBy": FirebaseAuth.instance.currentUser?.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pre-booking request posted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Database Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Blood Support"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Planning a surgery or delivery? Pre-book donors in your city.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // 1. Blood Group Selection
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
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedBlood = v!),
            ),

            const Divider(height: 40),
            const Text(
              "Targeted Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 2. District Selection (From Register Code)
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
                _selectedCity = null; // Reset city when district changes
              }),
            ),
            const SizedBox(height: 15),

            // 3. City Selection (Cascading logic from Register Code)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "City/Area",
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

            const SizedBox(height: 25),

            // 4. Date Selection
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(5),
              ),
              title: Text(
                "Procedure Date: ${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}",
              ),
              trailing: const Icon(Icons.calendar_month, color: Colors.red),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _scheduledDate = picked);
              },
            ),
            const SizedBox(height: 15),

            // 5. Hospital & Reason
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: "Hospital Name",
                prefixIcon: Icon(Icons.local_hospital),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: "Reason (e.g., Surgery, Delivery)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : ElevatedButton(
                    onPressed: _submitPreBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "POST PRE-BOOK REQUEST",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}
