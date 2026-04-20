import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AmbulanceListScreen extends StatelessWidget {
  const AmbulanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Ambulances"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // You should add an 'ambulances' collection in Firestore
        stream: FirebaseFirestore.instance.collection('ambulances').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final a = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.airport_shuttle,
                    color: Colors.orange,
                  ),
                  title: Text(a["serviceName"] ?? "Ambulance"),
                  subtitle: Text("${a["area"]} | ${a["city"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      /* Logic to call a["phone"] */
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
}
