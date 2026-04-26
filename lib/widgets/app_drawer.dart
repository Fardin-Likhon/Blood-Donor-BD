import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- THE CRITICAL IMPORTS ---
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/services_screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/screens/admin_panel.dart';
import 'package:flutter_application_1/screens/pre_book_screen.dart'; 

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bloodtype, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    "Blood Donor BD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. Home
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),

          // 2. My Dashboard
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

          // 3. Pre-book Blood (Targeted Alerts)
          ListTile(
            leading: Icon(Icons.calendar_month, color: Colors.orange.shade800),
            title: const Text("Pre-book Blood"),
            subtitle: const Text("Surgery / Delivery Support"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PreBookScreen()),
              );
            },
          ),

          // 4. Emergency Services
          ListTile(
            leading: const Icon(Icons.emergency_share, color: Colors.red),
            title: const Text("Emergency Services"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesScreen()),
              );
            },
          ),

          const Divider(),

          // --- ADMIN PANEL CHECK ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donor')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                if (userData['role'] == 'admin') {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                    title: const Text("Admin Panel", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
              return const SizedBox.shrink();
            },
          ),

          const Spacer(),
          const Divider(),

          // 5. Logout
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