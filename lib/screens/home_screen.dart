import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- ADDED THIS
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../widgets/app_drawer.dart';
import 'request_blood_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();

  // Get the current user's ID to filter them out later
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Search States
  String? _selectedBloodGroup;
  String? _selectedDistrict;
  String? _selectedCity;
  Position? _currentPosition;

  // Locations matching Register Screen
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current date minus 90 days for eligibility
    DateTime thresholdDate = DateTime.now().subtract(const Duration(days: 90));

    // Base Query: Fetch all Donors
    Query baseQuery = FirebaseFirestore.instance
        .collection('donor')
        .where('userType', isEqualTo: 'Donor');

    // 1. Filter by Blood Group (Step 1)
    if (_selectedBloodGroup != null && _selectedBloodGroup != "All Groups") {
      baseQuery = baseQuery.where('bloodGroup', isEqualTo: _selectedBloodGroup);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blood Donor Network"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),

      // --- FLOATING ACTION BUTTON: REQUEST BLOOD ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RequestBloodScreen()),
        ),
        backgroundColor: Colors.red.shade900,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text(
          "Request Blood",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // --- STEP-BY-STEP SEARCH ---
          _buildStepByStepSearch(),

          // --- NEED HELP BANNER ---
          _buildHelpMessage(),

          // --- DONOR LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: baseQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter by District, City, and EXCLUDE SELF
                var donors = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // --- FIX: HIDE MYSELF FROM THE LIST ---
                  if (doc.id == _currentUserId) return false;

                  bool districtMatch =
                      (_selectedDistrict == null ||
                          _selectedDistrict == "All Districts")
                      ? true
                      : data['district'] == _selectedDistrict;

                  bool cityMatch =
                      (_selectedCity == null || _selectedCity == "All Cities")
                      ? true
                      : data['city'] == _selectedCity;

                  return districtMatch && cityMatch;
                }).toList();

                if (donors.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No donors found for this selection.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 5, bottom: 80),
                  itemCount: donors.length,
                  itemBuilder: (context, i) {
                    var data = donors[i].data() as Map<String, dynamic>;

                    // Eligibility Logic
                    DateTime lastDonation =
                        (data['lastDonationDate'] as Timestamp?)?.toDate() ??
                        DateTime(2000);
                    bool isAvailable = lastDonation.isBefore(thresholdDate);

                    // Distance Calculation
                    double? distance;
                    if (_currentPosition != null && data['lat'] != null) {
                      distance = _locationService.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        (data['lat'] as num).toDouble(),
                        (data['lng'] as num).toDouble(),
                      );
                    }
                    return _buildDonorCard(data, isAvailable, distance);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: INSTRUCTIONAL BANNER ---
  Widget _buildHelpMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_center, color: Colors.red.shade900, size: 20),
              const SizedBox(width: 8),
              Text(
                "How to get help?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Call a 'READY' donor for instant help. If no one is available, tap the button below to post a public request.",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dropdownLabel("Step 1: Choose Blood Group"),
          _customDropdown(
            value: _selectedBloodGroup ?? "All Groups",
            items: [
              "All Groups",
              "A+",
              "A-",
              "B+",
              "B-",
              "O+",
              "O-",
              "AB+",
              "AB-",
            ],
            onChanged: (val) => setState(
              () => _selectedBloodGroup = val == "All Groups" ? null : val,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdownLabel("Step 2: District"),
                    _customDropdown(
                      value: _selectedDistrict ?? "All Districts",
                      items: ["All Districts", ..._locations.keys],
                      onChanged: (val) => setState(() {
                        _selectedDistrict = val == "All Districts" ? null : val;
                        _selectedCity = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdownLabel("Step 3: City"),
                    DropdownButtonFormField<String>(
                      decoration: _dropdownDecoration(),
                      value: _selectedCity ?? "All Cities",
                      items: (_selectedDistrict == null)
                          ? [
                              const DropdownMenuItem(
                                value: "All Cities",
                                child: Text("All Cities"),
                              ),
                            ]
                          : ["All Cities", ..._locations[_selectedDistrict]!]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                      onChanged: (val) => setState(
                        () => _selectedCity = val == "All Cities" ? null : val,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _customDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: _dropdownDecoration(),
      value: value,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDonorCard(
    Map<String, dynamic> data,
    bool isAvailable,
    double? distance,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isAvailable ? Colors.red : Colors.grey.shade400,
          child: Text(
            data['bloodGroup'] ?? "?",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          data['displayName'] ?? "Donor",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${data['city']}, ${data['district']}"),
            const SizedBox(height: 4),
            Row(
              children: [
                _badge(
                  isAvailable ? "READY" : "RECOVERING",
                  isAvailable ? Colors.green : Colors.grey,
                ),
                if (distance != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    "${distance.toStringAsFixed(1)} KM",
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.call,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
          onPressed: isAvailable
              ? () => _locationService.makeCall(data['phone'] ?? "")
              : null,
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
