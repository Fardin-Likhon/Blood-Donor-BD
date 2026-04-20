import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- ADD THIS
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/services_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/admin_panel.dart'; // <--- ADD THIS

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Center(
              child: Text(
                "Blood Donor BD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 1. Home Link
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),

          // 2. Dashboard Link
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("My Dashboard"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),

          // 3. Emergency Services Link
          ListTile(
            leading: const Icon(Icons.emergency),
            title: const Text("Emergency Services"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesScreen()),
              );
            },
          ),

          // --- SMART ADMIN PANEL LINK ---
          // This only appears if the logged-in user has role == 'admin' in Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donor')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;

                // Check if the user is an admin
                if (userData['role'] == 'admin') {
                  return ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPanel()),
                      );
                    },
                  );
                }
              }
              // If not an admin, return nothing (an empty box)
              return const SizedBox.shrink();
            },
          ),

          const Spacer(),
          const Divider(),

          // 4. Logout Link
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
