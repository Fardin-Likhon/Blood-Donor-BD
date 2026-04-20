import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("System Administration"),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.red,
            tabs: [
              Tab(icon: Icon(Icons.volunteer_activism), text: "Donors"),
              Tab(icon: Icon(Icons.person_search), text: "Non-Donors"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserListView(userType: "Donor"),
            UserListView(userType: "Non-Donor"),
          ],
        ),
      ),
    );
  }
}

class UserListView extends StatelessWidget {
  final String userType;
  const UserListView({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final LocationService _locationService = LocationService();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donor')
          .where('userType', isEqualTo: userType)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var users = snapshot.data!.docs;

        if (users.isEmpty) {
          return Center(child: Text("No $userType registered yet."));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            var data = users[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: userType == "Donor"
                      ? Colors.red
                      : Colors.blue,
                  child: Text(
                    data['bloodGroup'] ?? "?",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(data['displayName'] ?? "Unnamed User"),
                subtitle: Text(
                  "${data['city']}, ${data['district']}\nPhone: ${data['phone']}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () =>
                          _locationService.makeCall(data['phone'] ?? ""),
                    ),
                    // Delete button for Admin
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => _deleteUser(context, users[i].id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteUser(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User?"),
        content: const Text(
          "This will permanently remove this user from the system.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('donor').doc(uid).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
