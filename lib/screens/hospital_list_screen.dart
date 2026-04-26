import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalListScreen extends StatelessWidget {
  const HospitalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Hospitals"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Create a 'hospitals' collection in Firestore
        stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final h = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.blue),
                  title: Text(h["hospitalName"] ?? "Hospital"),
                  subtitle: Text(h["address"] ?? "Location Not Specified"),
                  trailing: const Icon(Icons.map, color: Colors.blueGrey),
                  onTap: () {
                    // Tip: Use url_launcher to open Google Maps with the address
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
