import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class NearbyServiceScreen extends StatefulWidget {
  final String serviceType; // Must match Firestore: "hospitals" or "ambulances"
  const NearbyServiceScreen({super.key, required this.serviceType});

  @override
  State<NearbyServiceScreen> createState() => _NearbyServiceScreenState();
}

class _NearbyServiceScreenState extends State<NearbyServiceScreen> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _isPermissionDenied = false;
      });
    } catch (e) {
      setState(() => _isPermissionDenied = true);
      debugPrint("Location Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Nearby ${widget.serviceType == 'hospitals' ? 'Hospitals' : 'Ambulances'}",
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initLocation(),
          ),
        ],
      ),
      body: _isPermissionDenied
          ? _buildErrorUI(
              "GPS Permission Denied. Please allow location access in Chrome.",
            )
          : _currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 15),
                  Text("Finding your location..."),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.serviceType)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return _buildErrorUI("Firebase Error: ${snapshot.error}");
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // --- DATA PROCESSING WITH SAFETY ---
                List<Map<String, dynamic>> items = [];

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;

                  // Safety Check: Only add if lat and lng exist
                  if (data.containsKey('lat') && data.containsKey('lng')) {
                    try {
                      double lat = (data['lat'] as num).toDouble();
                      double lng = (data['lng'] as num).toDouble();

                      double distance = _locationService.calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        lat,
                        lng,
                      );

                      data['distance'] = distance;
                      items.add(data);
                    } catch (e) {
                      debugPrint("Skipping invalid document ${doc.id}: $e");
                    }
                  }
                }

                // Sort by nearest
                items.sort((a, b) => a['distance'].compareTo(b['distance']));

                if (items.isEmpty) {
                  return _buildErrorUI(
                    "No ${widget.serviceType} found in your city database.",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(
                            widget.serviceType == "hospitals"
                                ? Icons.local_hospital
                                : Icons.airport_shuttle,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          item['name'] ?? "Unknown Service",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item['distance'].toStringAsFixed(1)} KM away",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {
                            if (item['phone'] != null) {
                              _locationService.makeCall(item['phone']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildErrorUI(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
