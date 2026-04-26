import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';

class RequestListScreen extends StatelessWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final LocationService _locationService = LocationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Urgent Requests"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Step 1: Get the current Donor's blood group
        stream: FirebaseFirestore.instance.collection('donor').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String myBloodGroup = userData['bloodGroup'] ?? "";

          // Step 2: Listen to all blood requests
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blood_requests').snapshots(),
            builder: (context, requestSnapshot) {
              if (!requestSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Filter: Only show requests that match MY blood group
              var matchingRequests = requestSnapshot.data!.docs.where((doc) {
                var reqData = doc.data() as Map<String, dynamic>;
                return reqData['bloodGroup'] == myBloodGroup;
              }).toList();

              if (matchingRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text("No active requests for $myBloodGroup", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: matchingRequests.length,
                itemBuilder: (context, i) {
                  var req = matchingRequests[i].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(backgroundColor: Colors.red, child: const Icon(Icons.emergency, color: Colors.white)),
                      title: Text("URGENT: ${req['bloodGroup']} Needed", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      subtitle: Text("At: ${req['hospitalName']}\nReason: ${req['reason']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green, size: 30),
                        onPressed: () => _locationService.makeCall(req['phone'] ?? ""),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}