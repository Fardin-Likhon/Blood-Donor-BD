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

  Future<void> _submitRequest() async {
    if (_hospitalController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _loading = true);
    try {
      // This creates the 'blood_requests' collection automatically
      await FirebaseFirestore.instance.collection('blood_requests').add({
        "hospitalName": _hospitalController.text.trim(),
        "phone": _phoneController.text.trim(),
        "reason": _reasonController.text.trim(),
        "bloodGroup": _selectedBlood,
        "requestedBy": FirebaseAuth.instance.currentUser?.uid,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Pending",
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Posted Successfully!")),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Blood"),
        backgroundColor: Colors.red.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Post an urgent blood requirement",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedBlood,
              decoration: const InputDecoration(
                labelText: "Blood Group Needed",
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
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: "Hospital Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Contact Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: "Reason/Details",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("POST REQUEST"),
                  ),
          ],
        ),
      ),
    );
  }
}
